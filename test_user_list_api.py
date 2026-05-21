import requests

def test():
    try:
        url = 'https://api.connectthrive.in/v1/getUserList'
        print(f"Fetching: {url}")
        res = requests.get(url, timeout=10)
        print("Status Code:", res.status_code)
        print("Response Content:", res.text[:2000])
    except Exception as e:
        print("Error fetching:", e)

if __name__ == "__main__":
    test()
