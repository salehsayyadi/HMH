import json
import logging
from typing import Optional, Any
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import AuditLog

logger = logging.getLogger("hmh.audit")

async def log_action(
    db: AsyncSession,
    action: str,
    actor_id: Optional[int] = None,
    actor_name: Optional[str] = None,
    target_type: Optional[str] = None,
    target_id: Optional[str] = None,
    before_state: Optional[Any] = None,
    after_state: Optional[Any] = None,
    ip_address: Optional[str] = None,
    status: str = "success"
) -> AuditLog:
    """
    Records an immutable audit event in compliance with Part 29.
    Never stores passwords, tokens, or sensitive credentials.
    """
    def sanitize(val):
        if val is None:
            return None
        if isinstance(val, (dict, list)):
            s = json.dumps(val, default=str)
        else:
            s = str(val)
        # Extra safety check against accidental token/password leaks
        for secret_kw in ["password", "token", "secret", "authorization"]:
            if secret_kw in s.lower():
                return "[FILTERED_SENSITIVE_DATA]"
        return s

    audit_entry = AuditLog(
        actor_id=actor_id,
        actor_name=actor_name,
        action=action,
        target_type=target_type,
        target_id=str(target_id) if target_id is not None else None,
        before_state=sanitize(before_state),
        after_state=sanitize(after_state),
        ip_address=ip_address,
        status=status
    )
    db.add(audit_entry)
    # Note: don't commit here so it participates in the caller transaction, or flush if needed
    try:
        await db.flush()
    except Exception as e:
        logger.error(f"Audit log flush error: {e}")
    return audit_entry
