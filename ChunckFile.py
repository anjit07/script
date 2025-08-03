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

    def retrieve_chunks(query,vectorstore, top_k=5):
    results = vectorstore.similarity_search(query, k=top_k*2)  # fetch more to be safe
    unique_results = []
    seen_contents = set()

    for doc in results:
        if doc.page_content not in seen_contents:
            unique_results.append(doc)
            seen_contents.add(doc.page_content)
        if len(unique_results) >= top_k:
            break

    return unique_results


