"""FastAPI application and server entry point."""

import uvicorn
from fastapi import FastAPI

app = FastAPI()


@app.get("/foo")
def get_foo() -> str:
    """Return the example response."""
    return "bar"


def main() -> None:
    """Start the API server on localhost port 8000."""
    uvicorn.run(app, host="127.0.0.1", port=8000)


if __name__ == "__main__":
    main()
