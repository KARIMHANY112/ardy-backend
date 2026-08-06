"""Buyer preference profile logic for the Land Advisor.

Pure, deterministic functions (no LLM, no DB) so the "learning" behaviour can be
unit-tested. `extract_preferences` pulls structured constraints out of a single buyer
message; `merge_preferences` accumulates them across turns; `build_profile_summary`
renders the profile back into text for the embedding query and the LLM prompt.

Recognised preference keys: budget_min, budget_max, size_min, size_max,
land_type, location, offer_intent (all optional).
"""
import re

# Land-type keywords -> canonical type. Must match Listing.type's actual values
# (land / factory / shop — see models/listing.dart's ListingCategory), not some
# separate taxonomy, since _preference_filters ilike-matches this straight
# against the DB column. Ordered so the more specific categories are checked
# before the generic "land" catch-all (e.g. "factory land" should match factory).
_LAND_TYPE_KEYWORDS = {
    "factory": ["factory", "industrial", "warehouse", "plant", "manufactur"],
    "shop": ["shop", "commercial", "retail", "store", "office", "mall"],
    "land": ["land", "plot", "agricultural", "agriculture", "farm", "farmland", "crop", "cultivat", "acreage"],
}

# Egyptian governorates / common cities we recognise in free text.
_LOCATIONS = [
    "cairo", "giza", "alexandria", "luxor", "aswan", "mansoura", "tanta", "zagazig",
    "ismailia", "suez", "port said", "damietta", "fayoum", "faiyum", "beni suef",
    "minya", "asyut", "sohag", "qena", "hurghada", "sharm el sheikh", "6th of october",
    "6 october", "new cairo", "sheikh zayed", "north coast", "sahel", "ain sokhna",
    "mansoura", "damanhur", "kafr el sheikh", "banha", "shibin el kom",
]

# Whether the buyer wants to rent, buy, or specifically buy second-hand. Maps to an
# offer_type filter in advisor._preference_filters — note "buy" deliberately allows
# both sale and resale there, which is why the intent isn't just an OfferType value.
# Checked resale-first: "resale" also contains "sale", and renting beats buying when
# a message mentions both, since "rent" is the more specific ask.
_OFFER_INTENT_KEYWORDS = {
    "resale": ["resale", "resell", "second hand", "second-hand", "إعادة بيع", "اعادة بيع"],
    "rent": ["rent", "rental", "lease", "leasing", "tenant", "إيجار", "ايجار", "تأجير", "استئجار"],
    "buy": ["buy", "buying", "purchase", "for sale", "شراء", "للبيع", "تمليك"],
}

# Words that qualify a number as an upper vs lower bound.
_MAX_HINTS = ["under", "below", "less than", "up to", "max", "maximum", "at most", "no more than", "cheaper than", "within"]
_MIN_HINTS = ["over", "above", "more than", "at least", "min", "minimum", "starting from", "from"]

_SIZE_UNITS = ["feddan", "feddans", "acre", "acres", "m2", "sqm", "sq m", "square meter", "square metre", "meter", "metre"]

# How many m² each recognised unit is worth. Size bounds are stored normalised to
# m² so a profile that picks up "5 feddan" on one turn and "min 2000 sqm" on the
# next stays comparable — and so they can be matched against Listing.size_sqm.
# An acre (4,046.86 m²) is within 4% of a feddan, and locally the two words are
# used interchangeably, so the distinction doesn't change which listings match.
_SQM_PER_UNIT = {
    "feddan": 4200.0, "feddans": 4200.0,
    "acre": 4046.86, "acres": 4046.86,
    "m2": 1.0, "sqm": 1.0, "sq m": 1.0,
    "square meter": 1.0, "square metre": 1.0, "meter": 1.0, "metre": 1.0,
}

# Which unit to phrase the profile summary back in, per unit word.
_UNIT_FAMILY = {u: ("feddan" if f > 1.0 else "sqm") for u, f in _SQM_PER_UNIT.items()}


def _to_number(raw: str, suffix: str) -> float:
    """Turns a captured number + optional magnitude suffix into a float.
    e.g. ('2', 'million') -> 2_000_000 ; ('500', 'k') -> 500_000 ; ('1,250,000', '') -> 1250000."""
    value = float(raw.replace(",", "").strip())
    suffix = (suffix or "").lower().strip()
    if suffix in ("k", "thousand"):
        value *= 1_000
    elif suffix in ("m", "mn", "million", "millions"):
        value *= 1_000_000
    elif suffix in ("bn", "billion"):
        value *= 1_000_000_000
    return value


# A number, optional magnitude suffix. Kept loose on purpose.
_NUMBER = r"(\d[\d,]*(?:\.\d+)?)\s*(k|m|mn|bn|thousand|million|millions|billion)?"


def _nearest_hint(text: str, match_start: int) -> str | None:
    """Looks at the ~25 chars before a number to decide if it's a min or max bound."""
    window = text[max(0, match_start - 25):match_start]
    for hint in _MAX_HINTS:
        if hint in window:
            return "max"
    for hint in _MIN_HINTS:
        if hint in window:
            return "min"
    return None


def _extract_budget(text: str) -> dict:
    """Pulls budget bounds from money-flavoured numbers (those near a currency word
    or a min/max hint). Avoids grabbing sizes like '5 feddan'."""
    prefs: dict = {}
    # Word boundaries matter: "le" (Egyptian pound) must not match inside "least"/"sale".
    currency = r"\b(?:egp|pounds?|le|جنيه)\b"

    # between X and Y
    between = re.search(rf"between\s+{_NUMBER}\s+and\s+{_NUMBER}", text)
    if between:
        low = _to_number(between.group(1), between.group(2))
        high = _to_number(between.group(3), between.group(4))
        prefs["budget_min"], prefs["budget_max"] = min(low, high), max(low, high)
        return prefs

    money_words = re.compile(r"\b(?:budget|price|cost|worth|afford|spend)\b")
    size_unit_next = re.compile(rf"\s*(?:{'|'.join(re.escape(u) for u in _SIZE_UNITS)})\b")
    for m in re.finditer(_NUMBER, text):
        raw, suffix = m.group(1), m.group(2)
        after = text[m.end():m.end() + 12].lower()
        window_before = text[max(0, m.start() - 25):m.start()].lower()
        looks_like_money = (
            bool(re.match(rf"\s*{currency}", after))
            or bool(re.search(currency, window_before))
            or bool(money_words.search(window_before))
            # A bare magnitude suffix ("30M", "1.5m") is itself a strong money signal in
            # this domain — sizes are always given with an explicit unit (feddan/sqm),
            # never as a plain order-of-magnitude number — unless a size unit follows
            # right after it ("5k sqm"), in which case it's a size, not a budget.
            or (bool(suffix) and not size_unit_next.match(after))
        )
        hint = _nearest_hint(text, m.start())
        if not looks_like_money:
            continue
        value = _to_number(raw, suffix)
        if hint == "max":
            prefs["budget_max"] = value
        elif hint == "min":
            prefs["budget_min"] = value
        else:
            prefs["budget_max"] = value  # a bare "budget 2m" reads as a ceiling
    return prefs


def _extract_size(text: str) -> dict:
    """Size bounds, normalised to m².

    The unit word is part of the meaning, not decoration: "5 feddan" is 21,000 m²,
    and dropping the unit (as this used to) made it indistinguishable from 5 m².
    `size_unit` records the family the buyer spoke in, purely so the profile can be
    read back to them in the same terms.
    """
    prefs: dict = {}
    # Longest-first so "square metre" wins over "metre" and "feddans" over "feddan".
    unit_group = "|".join(re.escape(u) for u in sorted(_SIZE_UNITS, key=len, reverse=True))
    for m in re.finditer(rf"{_NUMBER}\s*({unit_group})\b", text):
        unit = m.group(3)
        value = _to_number(m.group(1), m.group(2)) * _SQM_PER_UNIT[unit]
        hint = _nearest_hint(text, m.start())
        if hint == "max":
            prefs["size_max"] = value
        elif hint == "min":
            prefs["size_min"] = value
        else:
            prefs["size_min"] = prefs["size_max"] = value
        prefs["size_unit"] = _UNIT_FAMILY[unit]
    return prefs


def _extract_land_type(text: str) -> dict:
    # Leading \b so keyword stems match as whole words: avoids "house" hitting "warehouse".
    for canonical, keywords in _LAND_TYPE_KEYWORDS.items():
        if any(re.search(rf"\b{kw}", text) for kw in keywords):
            return {"land_type": canonical}
    return {}


def _extract_offer_intent(text: str) -> dict:
    for intent, keywords in _OFFER_INTENT_KEYWORDS.items():
        for kw in keywords:
            # Latin keywords need a word boundary so "rent" doesn't fire on "current";
            # Arabic ones are matched as plain substrings, since \b sits between two
            # word characters in prefixed forms like "للإيجار" and would never match.
            hit = re.search(rf"\b{kw}", text) if kw.isascii() else kw in text
            if hit:
                return {"offer_intent": intent}
    return {}


def _extract_location(text: str) -> dict:
    for loc in _LOCATIONS:
        if re.search(rf"\b{re.escape(loc)}\b", text):
            return {"location": loc}
    return {}


def extract_preferences(message: str) -> dict:
    """Deterministically extract buyer constraints from one message.
    Returns only the keys that were found (never None values)."""
    text = (message or "").lower()
    prefs: dict = {}
    prefs.update(_extract_budget(text))
    prefs.update(_extract_size(text))
    prefs.update(_extract_land_type(text))
    prefs.update(_extract_location(text))
    prefs.update(_extract_offer_intent(text))
    return prefs


def merge_preferences(existing: dict | None, new: dict | None) -> dict:
    """Accumulate a profile: newer non-empty values win, older values persist.
    This is what makes the advisor 'learn' over the course of the conversation."""
    merged = dict(existing or {})
    for key, value in (new or {}).items():
        if value is not None and value != "":
            merged[key] = value
    return merged


def build_profile_summary(prefs: dict | None) -> str:
    """Human-readable one-liner describing the accumulated profile, used both in the
    embedding query text and in the LLM system context."""
    prefs = prefs or {}
    parts: list[str] = []
    intent = prefs.get("offer_intent")
    if intent:
        parts.append({"rent": "looking to rent", "buy": "looking to buy", "resale": "looking for a resale"}[intent])
    land_type = prefs.get("land_type")
    if land_type:
        parts.append("land" if land_type == "land" else f"{land_type} land")
    if prefs.get("location"):
        parts.append(f"in {prefs['location'].title()}")
    if prefs.get("budget_min") is not None and prefs.get("budget_max") is not None:
        parts.append(f"budget {int(prefs['budget_min']):,}-{int(prefs['budget_max']):,} EGP")
    elif prefs.get("budget_max") is not None:
        parts.append(f"budget up to {int(prefs['budget_max']):,} EGP")
    elif prefs.get("budget_min") is not None:
        parts.append(f"budget from {int(prefs['budget_min']):,} EGP")
    # Bounds are held in m²; read them back in whichever unit the buyer used.
    unit = prefs.get("size_unit", "sqm")
    divisor = 4200.0 if unit == "feddan" else 1.0
    label = "feddan" if unit == "feddan" else "m^2"

    def size(value: float) -> str:
        return f"{value / divisor:g} {label}"

    if prefs.get("size_min") is not None and prefs.get("size_max") is not None:
        if prefs["size_min"] == prefs["size_max"]:
            parts.append(f"around {size(prefs['size_min'])}")
        else:
            parts.append(f"size {prefs['size_min'] / divisor:g}-{size(prefs['size_max'])}")
    elif prefs.get("size_max") is not None:
        parts.append(f"size up to {size(prefs['size_max'])}")
    elif prefs.get("size_min") is not None:
        parts.append(f"size from {size(prefs['size_min'])}")
    return ", ".join(parts)
