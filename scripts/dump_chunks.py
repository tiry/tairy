import pickle

# Path to your index.pkl (adjust if needed)
pkl_path = '/home/tiry/a0_data_dir/memory/default/index.pkl'

# Load the pickled data
with open(pkl_path, 'rb') as f:
    docstore, id_map = pickle.load(f)

# Access the document dictionary (ID -> Object with page_content)
doc_dict = docstore._dict

print(f"Total chunks: {len(doc_dict)}\n")

# Loop through and display up to 500 chars per chunk for readability
for doc_id, obj in doc_dict.items():
    chunk_preview = obj.page_content[:500]  # truncate long text
    print(f"Doc ID: {doc_id}\nContent preview:\n{chunk_preview}\n{'-'*40}")


