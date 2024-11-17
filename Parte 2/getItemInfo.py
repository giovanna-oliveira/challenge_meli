# Realizar una análise sobre a oferta / vitrine das opções de productos que respondam a
# distintas buscar no site do Mercadolibre.com.ar
# Perguntas
# 1) Varrer uma lista de mais de 150 itens ids no serviço público:
# https://api.mercadolibre.com/sites/MLA/search?q=chromecast&limit=50#json
# Nesse caso particular e somente como exemplo, são resultado para a busca
# “chromecast”, porém deverá eleger outros términos para o experimento que
# permitam enriquecer uma análise em um hipotético dashboard (ex: Google Home,
# Apple TV, Amazon Fire TV, e outros para poder comparar dispositivos portáteis, ou
# até mesmo eleger outros e que você tenha interesse em comparar).
# 2) Para cada resultado, realizar o correspondente GET por Item_id no recurso publico:
# https://api.mercadolibre.com/items/{Item_Id}
# 3) Escrever os resultados em um arquivo plano delimitado por vírgulas,
# desnormalizando o JSON obtido no passo anterior, em quantos campos sejam
# necessários para guardar as variáveis que te interesse modelar.


import pandas as pd
import requests
import math


headers ={
    "Accept": "application/json",
    "Content-Type": "application/json",
}



# listing all search categories
categories = [
                'chromecast', 
                'apple tv', 
                'google home', 
                'amazon fire tv'
                ]
# initializing variables used in loop
results = []
for category in categories:
    offset = 0
    # for each category, we get their total results by making a api call limited for only one result 
    url = 'https://api.mercadolibre.com/sites/MLA/search?q={}&limit=1#json'.format(category)
    response = requests.request(
            'GET',
            url,
            headers = headers
    ).json()
    # within the response, we retrieve the total results by navegating in paging>total
    total_itens = response.get('paging').get('total')
    # using the total results, it's possible to determine the amount of iterations necessary to traverse the entire list divinding that number by 50 (limit).
    iterations = math.ceil(total_itens/50)

    # for each iteration, we make a api call changing the offset to navegate through the pages
    for i in range(iterations):
        url = 'https://api.mercadolibre.com/sites/MLA/search?q={}&limit=50&offset={}#json'.format(category,offset)
        response = requests.request(
            'GET',
            url,
            headers = headers
        ).json()

        # the result of each api call is stored in the results list
        results = results + response['results']

        offset = 50*i
        i+=1

# after traversing through all the categories, for each result in the results list we append it's id to the array_ids_to_search
array_ids_to_search = []
for result in results:
    array_ids_to_search.append(result['id'])



# since a product could appear in multiple categories results, it's best to remove the duplicates
array_ids_to_search = list(dict.fromkeys(array_ids_to_search))


array_items = []


# for each value in the before mentioned array, we make a api call to retrieve the information from each item
for item in array_ids_to_search:
    url = 'https://api.mercadolibre.com/items/{}'.format(item)
    response = requests.request(
        'GET',
        url,
        headers = headers
    )
    a_json = response.json()
    # appending the result to an array
    array_items.append(a_json)


# transforming the array into a dataframe for data manipulation
df_items = pd.DataFrame(array_items)


# with this function, we can transform fields in an array-like format into columns
def transform_array_into_columns(row):
    for i in range(len(row)-1):
        df_items[row[i].get('id')] = row[i].get('value_name')



# applying before mentioned function to applicable fields
df_items.apply(lambda x: transform_array_into_columns(x['sale_terms']), axis=1)
df_items.apply(lambda x: transform_array_into_columns(x['attributes']), axis=1)
df_items.apply(lambda x: transform_array_into_columns(x['variations']), axis=1)


# for the other nested fields, it's a simple navigation 
df_items['shipping_mode'] = df_items.apply(lambda x: x['shipping'].get('mode'), axis=1)
df_items['free_shipping'] = df_items.apply(lambda x: x['shipping'].get('free_shipping'), axis=1)
df_items['logistic_type'] = df_items.apply(lambda x: x['shipping'].get('logistic_type'), axis=1)


df_items['seller_city'] = df_items.apply(lambda x: x['seller_address'].get('city').get('name'), axis=1)
df_items['seller_state'] = df_items.apply(lambda x: x['seller_address'].get('state').get('name'), axis=1)
df_items['seller_country'] = df_items.apply(lambda x: x['seller_address'].get('country').get('name'), axis=1)


# removing columns and cleaning the dataframe
df_items.drop(columns = [
                        'thumbnail_id', 
                        'thumbnail', 
                        'pictures', 
                        'video_id', 
                        'descriptions',
                        'non_mercado_pago_payment_methods',
                        'seller_contact',
                        'location',
                        'coverage_areas',
                        'listing_source',
                        'sub_status',
                        'catalog_product_id',
                        'deal_ids',
                        'automatic_relist',
                        'sale_terms',
                        'shipping',
                        'seller_address',
                        'attributes',
                        'variations',
                        'tags',
                        'warranty',
                        'catalog_listing',
                        'ALPHANUMERIC_MODEL',
                        'DEVICE_FORMAT',
                        'DEVICE_OPERATING_VOLTAGE',
                        'FREQUENCIES',
                        'GTIN',
                        'HEIGHT',
                        'LENGTH',
                        'MAX_VIDEO_RESOLUTION',
                        'MIN_OPERATING_SYSTEMS_REQUIRED',
                        'RECOMMENDED_DEVICES',
                        'SELLER_SKU', 
                        'WEIGHT',
                        'WIDTH',
                        'LINE', 
                        'MPN', 
                        'REMOTE_CONTROL_TYPE',
                        'ANATEL_HOMOLOGATION_NUMBER', 
                        'PACKAGE_HEIGHT', 
                        'PACKAGE_LENGTH',
                        'PACKAGE_WEIGHT', 
                        'PACKAGE_WIDTH',
                        'PRODUCT_FEATURES',
                        'SHIPMENT_PACKING', 
                        'EMPTY_GTIN_REASON', 
                        'INCLUDES_POWER_ADAPTER',
                        'IS_KIT', 
                        'PRODUCT_DATA_SOURCE', 
                        'ADDITIONAL_INFO_REQUIRED',
                        'PRODUCT_TYPE',
                        'SIZE'
                        ], inplace = True) 


# saving the result into a csv
df_items.to_csv('Items.csv',sep=',', index=False, encoding='utf-8-sig')


