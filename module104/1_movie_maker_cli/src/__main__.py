from cortex_client import InputMessage, OutputMessage
from faker import Faker

def main(params):
    msg = InputMessage.from_params(params)
    fake = Faker()
    name_of_movie = msg.payload.get('name_of_movie')
    movie = {'name_of_movie': name_of_movie, 'lead_1': fake.name(), 'lead_2': fake.name(), 'support_1': fake.name(), 'support_2': fake.name()}
    return OutputMessage.create().with_type('cortex/Text').with_payload({'movie': movie}).to_params()
