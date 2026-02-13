from ..asgi import application

from fastapi import FastAPI
from .routers import users, lo, auction, le, fin


app = FastAPI()

app.include_router(users.router)
app.include_router(lo.router)
app.include_router(auction.router)
app.include_router(le.router)
app.include_router(fin.router)


@app.get('/')
def home():
    return 'Welcome to Loannect!'
