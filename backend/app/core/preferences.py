"""Buyer preference profile logic for the Land Advisor.

Pure, deterministic functions (no LLM, no DB) so the "learning" behaviour can be
unit-tested. `extract_preferences` pulls structured constraints out of a single buyer
message; `merge_preferences` accumulates them across turns; `build_profile_summary`
renders the profile back into text for the embedding query and the LLM prompt.

Recognised preference keys: budget_min, budget_max, size_min, size_max,
land_type, location (all optional).
"""
import re

# Land-type keywords -> canonical type. Ordered so more specific words win.
_LAND_TYPE_KEYWORDS = {
    "agricultural": ["agricultural", "agriculture", "farm", "farmland", "crop", "cultivat"],
    "residential": ["residential", "house", "home", "villa", "apartment", "housing"],
    "commercial": ["commercial", "shop", "retail", "store", "office", "mall"],
    "industrial": ["industrial", "factory", "warehouse", "plant"],
}

# Egyptian governorates / common cities we recognise in free text.
_LOCATIONS = [
    "cairo", "giza", "alexandria", "luxor", "aswan", "mansoura", "tanta", "zagazig",
    "ismailia", "suez", "port said", "damietta", "fayoum", "faiyum", "beni suef",
    "minya", "asyut", "sohag", "qena", "hurghada", "sharm el sheikh", "6th of october",
    "6 october", "new cairo", "sheikh zayed", "north coast", "sahel", "ain sokhna",
    "mansoura", "damanhur", "kafr el sheikh", "banha", "shibin el kom",
]

# Words that qualify a number as an upper vs lower bound.
_MAX_HINTS = ["under", "below", "less than", "up to", "max", "maximum", "at most", "no more than", "cheaper than", "within"]
_MIN_HINTS = ["over", "above", "more than", "at least", "min", "minimum", "starting from", "from"]

_SIZE_UNITS = ["feddan", "feddans", "acre", "acres", "m2", "sqm", "sq m", "square meter", "square metre", "meter", "metre"]


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
    for m in re.finditer(_NUMBER, text):
        raw, suffix = m.group(1), m.group(2)
        after = text[m.end():m.end() + 12].lower()
        window_before = text[max(0, m.start() - 25):m.start()].lower()
        looks_like_money = (
            bool(re.match(rf"\s*{currency}", after))
            or bool(re.search(currency, window_before))
            or bool(money_words.search(window_before))
        )
        hint = _nearest_hint(text, m.start())
        # Only treat as budget if it reads like money or carries a magnitude suffix with a bound hint.
        if not looks_like_money and not (suffix and hint):
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
    prefs: dict = {}
    unit_group = "|".join(re.escape(u) for u in _SIZE_UNITS)
    for m in re.finditer(rf"{_NUMBER}\s*({unit_group})\b", text):
        value = _to_number(m.group(1), m.group(2))
        hint = _nearest_hint(text, m.start())
        if hint == "max":
            prefs["size_max"] = value
        elif hint == "min":
            prefs["size_min"] = value
        else:
            prefs["size_min"] = prefs["size_max"] = value
    return prefs


def _extract_land_type(text: str) -> dict:
    # Leading \b so keyword stems match as whole words: avoids "house" hitting "warehouse".
    for canonical, keywords in _LAND_TYPE_KEYWORDS.items():
        if any(re.search(rf"\b{kw}", text) for kw in keywords):
            return {"land_type": canonical}
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
    if prefs.get("land_type"):
        parts.append(f"{prefs['land_type']} land")
    if prefs.get("location"):
        parts.append(f"in {prefs['location'].title()}")
    if prefs.get("budget_min") is not None and prefs.get("budget_max") is not None:
        parts.append(f"budget {int(prefs['budget_min']):,}-{int(prefs['budget_max']):,} EGP")
    elif prefs.get("budget_max") is not None:
        parts.append(f"budget up to {int(prefs['budget_max']):,} EGP")
    elif prefs.get("budget_min") is not None:
        parts.append(f"budget from {int(prefs['budget_min']):,} EGP")
    if prefs.get("size_min") is not None and prefs.get("size_max") is not None:
        if prefs["size_min"] == prefs["size_max"]:
            parts.append(f"around {prefs['size_min']:g} feddan/m^2")
        else:
            parts.append(f"size {prefs['size_min']:g}-{prefs['size_max']:g} feddan/m^2")
    elif prefs.get("size_max") is not None:
        parts.append(f"size up to {prefs['size_max']:g} feddan/m^2")
    elif prefs.get("size_min") is not None:
        parts.append(f"size from {prefs['size_min']:g} feddan/m^2")
    return ", ".join(parts)
