#!/usr/bin/env python3
"""
Upload documents to Open-WebUI RAG system via API
Usage: python3 upload-document.py <pdf-file> [webui-url] [api-key]
"""

import sys
import requests
import os

def upload_document(file_path, webui_url="http://localhost:8080", api_key=None):
    """Upload a document to Open-WebUI"""
    
    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        return False
    
    # API endpoint
    url = f"{webui_url}/api/v1/documents/upload"
    
    # Prepare file
    files = {
        'file': (os.path.basename(file_path), open(file_path, 'rb'))
    }
    
    # Headers
    headers = {}
    if api_key:
        headers['Authorization'] = f'Bearer {api_key}'
    
    print(f"📤 Uploading: {file_path}")
    print(f"   To: {webui_url}")
    
    try:
        response = requests.post(url, files=files, headers=headers)
        
        if response.status_code == 200:
            print("✅ Upload successful!")
            result = response.json()
            print(f"   Document ID: {result.get('id', 'N/A')}")
            print(f"   Status: {result.get('status', 'N/A')}")
            return True
        else:
            print(f"❌ Upload failed: HTTP {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to {webui_url}")
        print("   Make sure Open-WebUI is running")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 upload-document.py <file-path> [webui-url] [api-key]")
        print("")
        print("Examples:")
        print("  python3 upload-document.py document.pdf")
        print("  python3 upload-document.py document.pdf http://your-ip:8080")
        print("  python3 upload-document.py document.pdf http://your-ip:8080 your-api-key")
        sys.exit(1)
    
    file_path = sys.argv[1]
    webui_url = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:8080"
    api_key = sys.argv[3] if len(sys.argv) > 3 else None
    
    success = upload_document(file_path, webui_url, api_key)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
