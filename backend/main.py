from fastapi import FastAPI
from pydantic import BaseModel
import drug_fetch

app = FastAPI()


class SearchQuery(BaseModel):
    query: str


@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.post("/search")
async def search(search_query: SearchQuery):
    results = drug_fetch.search_medicine(search_query.query)
    return {"results": results[:20]}


@app.get("/medicine/{medicine_id}")
async def get_medicine_details(medicine_id: str):
    medicines = drug_fetch.load_medicines()

    for med in medicines:
        if med["slug"] == medicine_id:
            return med

    return {"error": "Medicine not found"}
