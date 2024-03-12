from web3 import Web3


def main():
    #blast = Web3(Web3.HTTPProvider('https://thrilling-tiniest-paper.blast-mainnet.quiknode.pro/6b90d9c6cee6574a29d26ca8616fedc33ac8d5bf'))
    blast = Web3(Web3.HTTPProvider('https://rpc.blast.io'))
    # Get the latest block number
    latest_block_number = blast.eth.block_number

    # Define a list to store block numbers
    block_numbers = list(range(392713, latest_block_number + 1))

    # Send batch requests to get block timestamps
    batch = []
    for block_number in block_numbers:
        print(block_number)
        batch.append(blast.eth.get_block(block_number))

    timestamps = blast.eth.batch_call(batch)

    # Extract timestamps from the results
    for i, timestamp in enumerate(timestamps):
        print(f"Timestamp of block {block_numbers[i]}: {timestamp}")    

if __name__ == '__main__':
    try:
        main()
    except:
        raise Exception