"""FastAPI application and server entry point."""

import secrets
from typing import Annotated

import uvicorn
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials

security = HTTPBasic()


def verify_credentials(credentials: Annotated[HTTPBasicCredentials, Depends(security)]) -> None:
    """Require the temporary HTTP Basic credentials."""
    username_correct = secrets.compare_digest(credentials.username.encode("utf-8"), b"test")
    password_correct = secrets.compare_digest(credentials.password.encode("utf-8"), b"test")
    if not (username_correct and password_correct):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Basic"},
        )


app = FastAPI(dependencies=[Depends(verify_credentials)])


@app.get("/foo")
def get_foo() -> str:
    """Return the example response."""
    return "bar"


def main() -> None:
    """Start the API server on localhost port 8000."""
    uvicorn.run(app, host="127.0.0.1", port=8000)


if __name__ == "__main__":
    main()
