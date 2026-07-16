import logging

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from openai import OpenAI

from app.core.database import SessionLocal, get_db
from app.core.config import settings
from app.core.deps import get_optional_user
from app.core.preferences import (
    build_profile_summary,
    extract_preferences,
    merge_preferences,
)
from app.models.models import (
    ChatMessage,
    Conversation,
    Listing,
    ListingStatus,
    MessageRole,
    User,
)
from app.schemas.schemas import AdvisorQuery, AdvisorResponse, ListingOut

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/advisor", tags=["land-advisor"])

client = OpenAI(api_key=settings.openai_api_key)

# How many past messages (user + assistant) to replay into the LLM. Bounds token use
# on long conversations while keeping enough context to stay coherent.
HISTORY_LIMIT = 10


def embed_text(text: str) -> list[float]:
    response = client.embeddings.create(model=settings.embedding_model, input=text)
    return response.data[0].embedding


def build_listing_text(listing: Listing) -> str:
    """Flattens a listing's fields into text before embedding."""
    return (
        f"{listing.title}. {listing.type} land in {listing.location}. "
        f"{listing.size} feddan/m^2, priced at {listing.price} EGP. {listing.description or ''}"
    )


def embed_and_store_listing(listing_id) -> None:
    """Runs as a background task after a listing is approved (see listings.py review_listing).
    Opens its own session and refetches the listing rather than reusing the request-scoped
    `db`/`listing`, which may already be torn down by the time this actually runs.
    Swallow-and-log: a failed embedding shouldn't crash anything since it already went live —
    it just won't show up for the Land Advisor until retried."""
    db = SessionLocal()
    try:
        listing = db.query(Listing).filter(Listing.id == listing_id).first()
        if listing is None:
            return
        listing.embedding = embed_text(build_listing_text(listing))
        db.commit()
    except Exception:
        logger.exception("Failed to embed listing %s for the Land Advisor", listing_id)
    finally:
        db.close()


def _preference_filters(prefs: dict) -> list:
    """SQLAlchemy filter expressions derived from the accumulated buyer profile.
    This is how the conversation 'learns' to narrow the pgvector search over time."""
    filters = []
    if prefs.get("budget_max") is not None:
        filters.append(Listing.price <= prefs["budget_max"])
    if prefs.get("budget_min") is not None:
        filters.append(Listing.price >= prefs["budget_min"])
    if prefs.get("size_max") is not None:
        filters.append(Listing.size <= prefs["size_max"])
    if prefs.get("size_min") is not None:
        filters.append(Listing.size >= prefs["size_min"])
    if prefs.get("land_type"):
        filters.append(Listing.type.ilike(f"%{prefs['land_type']}%"))
    if prefs.get("location"):
        filters.append(Listing.location.ilike(f"%{prefs['location']}%"))
    return filters


def _search_listings(db: Session, query_embedding: list[float], prefs: dict, limit: int = 3) -> list[Listing]:
    """Vector search biased by the learned profile. Applies preference filters first;
    if that over-constrains to zero results, falls back to an unfiltered vector search
    so the buyer still gets the closest real listings. Either way, only live listings
    that actually exist are returned — the advisor never invents anything."""
    base = db.query(Listing).filter(
        Listing.status == ListingStatus.live, Listing.embedding.isnot(None)
    )
    ordered = lambda q: q.order_by(Listing.embedding.cosine_distance(query_embedding)).limit(limit).all()

    filters = _preference_filters(prefs)
    if filters:
        filtered = ordered(base.filter(*filters))
        if filtered:
            return filtered
    return ordered(base)


@router.post("/ask", response_model=AdvisorResponse)
def ask_advisor(
    payload: AdvisorQuery,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    """
    Multi-turn RAG flow:
    1. Load (or create) the conversation and its accumulated buyer profile
    2. Extract new preferences from this message and merge them into the profile
    3. Embed the message + profile summary, then vector-search live listings,
       biased/filtered by the learned profile (pgvector cosine distance)
    4. Replay prior turns + profile + matches to the LLM for a contextual reply
    5. Persist both turns and return the reply, matches, conversation id and profile
    """
    conversation = _load_or_create_conversation(db, payload.conversation_id, user)

    # Learn from this turn: accumulate the profile before searching.
    new_prefs = extract_preferences(payload.message)
    conversation.preferences = merge_preferences(conversation.preferences, new_prefs)
    prefs = conversation.preferences

    profile_summary = build_profile_summary(prefs)
    # Embed the message together with the running profile so similarity reflects the
    # whole conversation, not just the latest sentence.
    embed_input = f"{payload.message}\nBuyer profile: {profile_summary}" if profile_summary else payload.message
    query_embedding = embed_text(embed_input)

    top_matches = _search_listings(db, query_embedding, prefs)
    listings_summary = "\n".join(f"- {build_listing_text(m)}" for m in top_matches) or "No matching listings found."

    prior_messages = [
        {"role": m.role.value, "content": m.content}
        for m in conversation.messages[-HISTORY_LIMIT:]
    ]

    system_content = (
        "You are Ardy's Land Advisor. You are having an ongoing conversation with a buyer. "
        "Use the conversation history and the known buyer profile to give contextual advice. "
        "Recommend from the listings provided below only — never invent listings or details. "
        "If nothing fits, say so honestly. Be brief and specific about why each one fits."
    )
    if profile_summary:
        system_content += f"\n\nKnown buyer profile so far: {profile_summary}."

    messages = [
        {"role": "system", "content": system_content},
        *prior_messages,
        {"role": "user", "content": f"{payload.message}\n\nAvailable listings:\n{listings_summary}"},
    ]

    completion = client.chat.completions.create(model=settings.chat_model, messages=messages)
    reply = completion.choices[0].message.content

    # Persist both turns so the next request sees them.
    db.add(ChatMessage(conversation_id=conversation.id, role=MessageRole.user, content=payload.message))
    db.add(ChatMessage(conversation_id=conversation.id, role=MessageRole.assistant, content=reply))
    db.commit()

    return AdvisorResponse(
        reply=reply,
        matches=[ListingOut.model_validate(m) for m in top_matches],
        conversation_id=conversation.id,
        preferences=prefs,
    )


def _load_or_create_conversation(db: Session, conversation_id, user: User | None) -> Conversation:
    """Fetch an existing conversation by id, or start a new one. The id is an opaque
    session token — possession is authorization for anonymous buyers."""
    if conversation_id is not None:
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conversation is None:
            raise HTTPException(status_code=404, detail="Conversation not found")
        return conversation

    conversation = Conversation(user_id=user.id if user else None, preferences={})
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return conversation
