from sqlalchemy.orm import Session

from app.core.exceptions import ConflictException, ForbiddenException, NotFoundException
from app.crud import category as category_crud
from app.models.category import Category
from app.schemas.category_schema import CategoryCreate, CategoryUpdate


# ============================================================
# CREATE
# ============================================================

def create_custom_category(
    db: Session,
    user_id: int,
    data: CategoryCreate,
) -> Category:
    """
    Create a custom category for a user.
    Raises ConflictException if same name+type already exists
    for this user OR as a default category.
    """
    # Check against user's custom category
    existing_user = category_crud.get_category_by_name_type(
        db, user_id=user_id, name=data.name, type=data.type
    )
    if existing_user:
        raise ConflictException(
            f"You already have a {data.type} category named '{data.name}'"
        )

    # Check against default category
    existing_default = category_crud.get_category_by_name_type(
        db, user_id=None, name=data.name, type=data.type
    )
    if existing_default:
        raise ConflictException(
            f"A default {data.type} category named '{data.name}' already exists"
        )

    return category_crud.create_category(db, user_id, data)


# ============================================================
# READ
# ============================================================

def list_user_categories(
    db: Session,
    user_id: int,
    *,
    type_filter: str | None = None,
    include_inactive: bool = False,
) -> list[Category]:
    """
    List all categories available to a user.
    Optionally filter by type ('income' | 'expense').
    """
    if type_filter:
        return category_crud.get_categories_by_type(db, user_id, type_filter)

    return category_crud.get_user_categories(
        db, user_id, include_inactive=include_inactive
    )


def get_category_for_user(
    db: Session,
    user_id: int,
    category_id: int,
) -> Category:
    """
    Get a category if it's visible to this user
    (either their own or a default one).
    Raises NotFoundException otherwise.
    """
    category = category_crud.get_category_by_id(db, category_id)
    if not category:
        raise NotFoundException("Category not found")

    # Default categories (user_id = None) are visible to everyone
    if category.user_id is None:
        return category

    # Custom category must belong to the user
    if category.user_id != user_id:
        raise NotFoundException("Category not found")

    return category


# ============================================================
# UPDATE
# ============================================================

def update_custom_category(
    db: Session,
    user_id: int,
    category_id: int,
    data: CategoryUpdate,
) -> Category:
    """
    Update a user's custom category.
    Raises ForbiddenException if trying to modify a default category.
    Raises NotFoundException if category doesn't belong to user.
    """
    category = category_crud.get_category_by_id(db, category_id)
    if not category:
        raise NotFoundException("Category not found")

    # Cannot modify default categories
    if category.user_id is None:
        raise ForbiddenException("Cannot modify default categories")

    # Cannot modify another user's category
    if category.user_id != user_id:
        raise NotFoundException("Category not found")

    # Check duplicate name if name is being changed
    if data.name is not None and data.name != category.name:
        duplicate = category_crud.get_category_by_name_type(
            db, user_id=user_id, name=data.name, type=category.type
        )
        if duplicate:
            raise ConflictException(
                f"You already have a {category.type} category named '{data.name}'"
            )

    return category_crud.update_category(db, category, data)


# ============================================================
# DELETE
# ============================================================

def delete_custom_category(
    db: Session,
    user_id: int,
    category_id: int,
) -> None:
    """
    Delete a user's custom category.
    Raises ForbiddenException if trying to delete a default category.
    Raises NotFoundException if category doesn't belong to user.
    
    Note: Once transactions exist (Phase 3), we'll add a check
    to prevent deletion of categories that are in use.
    """
    category = category_crud.get_category_by_id(db, category_id)
    if not category:
        raise NotFoundException("Category not found")

    if category.user_id is None:
        raise ForbiddenException("Cannot delete default categories")

    if category.user_id != user_id:
        raise NotFoundException("Category not found")

    category_crud.delete_category(db, category)