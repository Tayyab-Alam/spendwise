from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.exceptions import UnauthorizedException
from app.core.security import decode_access_token
from app.crud import user as user_crud
from app.dependencies.db import get_db
from app.models.user import User

# HTTP Bearer scheme (yeh Swagger mein 🔒 lock icon laata hai)
bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """
    Dependency that extracts and validates the JWT token from
    the Authorization: Bearer <token> header.
    
    Returns the authenticated User.
    Raises UnauthorizedException if token is missing or invalid.
    """
    if credentials is None or not credentials.credentials:
        raise UnauthorizedException("Missing authentication token")

    token = credentials.credentials
    payload = decode_access_token(token)

    if payload is None:
        raise UnauthorizedException("Invalid or expired token")

    user_id_str = payload.get("sub")
    if user_id_str is None:
        raise UnauthorizedException("Invalid token payload")

    user = user_crud.get_user_by_id(db, int(user_id_str))
    if user is None:
        raise UnauthorizedException("User no longer exists")

    return user