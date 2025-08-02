from app.utils.config import settings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from typing import List

class ChunckFile:
    def __init__(self):
        self.chunk_size=settings.chunk_size
        self.chunk_overlap=settings.chunk_overlap

    def recursive_chunking(self, docs)-> List[str]:
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap
        )
        print(f"Chunking documents into size: {self.chunk_size} with overlap: {self.chunk_overlap}")
        return splitter.split_documents(docs)


