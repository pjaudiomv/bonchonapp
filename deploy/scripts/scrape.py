import urllib3
import json
from bs4 import BeautifulSoup
from unidecode import unidecode

spad_file = urllib3.PoolManager().request("GET", "https://bonchon.com/locations")
spad_data = spad_file.data.decode('utf-8', 'ignore')
soup = BeautifulSoup(spad_data, 'html.parser')
soup_data = soup.find_all("div", class_="locations-list-item")
new_bonchon = []

for i in soup_data:
    address_data = i.find_all("address")
    address = unidecode(address_data[0].get_text())
    address_1line = " ".join(address.split())
    address_split = [" ".join(a.split()) for a in address.split('\n')]
    address_list_list_strip = list(filter(None, address_split))
    address_list = [a.removesuffix(',') for a in address_list_list_strip]
    street_address = address_list[0]
    city = address_list[1]
    state = address_list[2]
    zip = address_list[3]

    name_data = i.find_all("h3", class_="locations-list-item__name")
    name = unidecode(name_data[0].get_text())
    tel_data = i.find_all("a", class_="locations-list-item__tel")
    link = [a['href'] for a in i.find_all("a", class_="locations-list-item__menu-link", href=True) if a.text][0]

    if len(tel_data) > 0:
        tel_d = unidecode(tel_data[0].get_text())
        tel = " ".join(tel_d.split())
    else:
        tel = ""

    bonchon_dict = {
            "location": name,
            "link": link,
            "phone": tel,
            "street": street_address,
            "city" : city,
            "state": state,
            "zip": zip
            }
    new_bonchon.append(bonchon_dict)

print(json.dumps(new_bonchon, indent=2))
