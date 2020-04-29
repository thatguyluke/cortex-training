from cortex_client import InputMessage, OutputMessage


def hello_world(params):
    msg = Message(params)
    cortex = Cortex.client(api_endpoint=msg.apiEndpoint, token=msg.token)
    text = msg.payload.get('text')
    return cortex.message({'message': 'Hello %s!' % text}).to_params()
