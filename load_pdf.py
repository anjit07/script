from langchain.document_loaders import PyMuPDFLoader
class PDFProcessor:
       
    
    # Define a function to load and extract text from PDF
    def load_pdf_with_langchain(self, pdf_path):
    
        print(f"Loading PDF from: {pdf_path}")
        # Use LangChain's built-in loader
        loader = PyMuPDFLoader(pdf_path)
        # Load the PDF into LangChain's document format
        documents = loader.load()

        print(f"Successfully loaded {len(documents)} document chunks from the PDF.")
        return documents
