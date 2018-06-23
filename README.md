# Web3Swift

[![CI Status](http://img.shields.io/travis/BlockStoreApp/Web3Swift.svg?style=flat)](https://travis-ci.org/BlockStoreApp/Web3Swift)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![codecov](https://codecov.io/gh/BlockStoreApp/Web3Swift/branch/develop/graph/badge.svg?token=SY7mpMQbGs)](https://codecov.io/gh/BlockStoreApp/Web3Swift)

## Installation

### CocoaPods

Web3 is available through [CocoaPods](https://cocoapods.org/pods/Web3Sw1ft). To install
it, simply add the following line to your `Podfile`:

```ruby
pod 'Web3Sw1ft'
```

## Sending ethers

To send some wei from an account with a private key `0x1636e10756e62baabddd4364010444205f1216bdb1644ff8f776f6e2982aa9f5` to an account with an address `0x79d2c50Ba0cA4a2C6F8D65eBa1358bEfc1cFD403` on a mainnet:

```swift
import Web3Swift

func send(weiAmount: Int) throws {
    let sender: PrivateKey = EthPrivateKey(
        hex: "0x1636e10756e62baabddd4364010444205f1216bdb1644ff8f776f6e2982aa9f5"
    )
    let recipient: BytesScalar = EthAddress(
        hex: "0x79d2c50Ba0cA4a2C6F8D65eBa1358bEfc1cFD403"
    )
    let network = InfuraNetwork(chain: "mainnet", apiKey: "metamask")
    _ = try SendRawTransactionProcedure(
        network: network,
        transactionBytes: EthDirectTransactionBytes(
            network: network,
            senderKey: sender,
            recipientAddress: recipient,
            weiAmount: EthNumber(value: weiAmount)
        )
    ).call()
}
```

If you want to specify gas price or gas amount take a look at [`EthDirectTransactionBytes.swift`](https://github.com/BlockStoreApp/Web3Swift/blob/develop/Web3Swift/TransactionBytes/EthDirectTransactionBytes.swift).

To send ether instead of wei:

```swift
func send(ethAmount: Int) throws {
	...
	_ = try SendRawTransactionProcedure(
		...,
		weiAmount: EthToWei(amount: ethAmount)
	).call()
}
```

## Dealing with ERC-20 tokens

### Sending tokens to an address

To send some ERC-20 tokens, for example [OmiseGO](https://etherscan.io/token/OmiseGo), we need to get the smart contract address.
OMG tokens are managed by smart contract at `0xd26114cd6EE289AccF82350c8d8487fedB8A0C07`.
In this example we send token from an account with a private key `0x1636e10756e62baabddd4364010444205f1216bdb1644ff8f776f6e2982aa9f5` to an account with an address `0x79d2c50Ba0cA4a2C6F8D65eBa1358bEfc1cFD403` on a mainnet:

```swift
import Web3Swift

let network: Network = InfuraNetwork(
    chain: "mainnet", apiKey: "metamask"
)

let sender: PrivateKey = EthPrivateKey(
    hex: "0x1636e10756e62baabddd4364010444205f1216bdb1644ff8f776f6e2982aa9f5"
)

let recipient: BytesScalar = EthAddress(
    hex: "0x79d2c50Ba0cA4a2C6F8D65eBa1358bEfc1cFD403"
)

let token: BytesScalar = EthAddress(
    hex: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07"
)

let amount: BytesScalar = EthNumber(
    hex: "0xde0b6b3a7640000" // 10^18 in hex that represents 1 OMG token
)

let response = try SendRawTransactionProcedure(
    network: network,
    transactionBytes: EthContractCallBytes(
        network: network,
        senderKey: sender,
        contractAddress: token,
        weiAmount: EthNumber(
            hex: "0x00" //We do not need to provide ethers to not payable functions.
        ),
        functionCall: EncodedABIFunction(
            signature: SimpleString(
                string: "transfer(address,uint256)"
            ),
            parameters: [
                ABIAddress(
                    address: recipient
                ),
                ABIUnsignedNumber(
                    origin: amount
                )
            ]
        )
    )
).call()

//If Ethereum network accepts the transaction, you could get transaction hash from the response. Otherwise, library will throw `DescribedError`
print(response["result"].string ?? "Something went wrong")
```

You can swiftly deal with other ERC-20 functions just by encoding another `EncodedABIFunction` .

### Sending delegated tokens to an address

Here is an example of encoding `transferFrom(from,to,value)` function

```swift
EncodedABIFunction(
    signature: SimpleString(
        string: "transferFrom(address,address,uint256)"
    ),
    parameters: [
        ABIAddress(
            address: EthAddress(
                hex: "0xFBb1b73C4f0BDa4f67dcA266ce6Ef42f520fBB98"
            )
        ),
        ABIAddress(
            address: EthAddress(
                hex: "0x79d2c50Ba0cA4a2C6F8D65eBa1358bEfc1cFD403"
            )
        ),
        ABIUnsignedNumber(
            origin: EthNumber(
                hex: "0x01"
            )
        )
    ]
)
```
More encoding example including advanced ones are placed at [`Example/Tests/ABI`](https://github.com/zeriontech/Web3Swift/tree/develop/Example/Tests/ABI)

### Checking an address balance
You do not need to send transaction for reading data from a smart contract. Here is an example of checking address balance by making a call to smart contract function `balanceOf(owner)`.

```swift
let balance = try HexAsDecimalString(
    hex: EthContractCall(
        network: InfuraNetwork(
            chain: "mainnet", apiKey: "metamask"
        ),
        contractAddress: EthAddress(
            hex: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07" //OmiseGO token contract
        ),
        functionCall: EncodedABIFunction(
            signature: SimpleString(
                string: "balanceOf(address)"
            ),
            parameters: [
                ABIAddress(
                    address: EthAddress(
                        hex: "0xFBb1b73C4f0BDa4f67dcA266ce6Ef42f520fBB98" //Bittrex
                    )
                )
            ]
        )
    )
).value()

print(balance) // 13098857909137917398909558 is 13 098 857.909137917398909558 OMG tokens
```

## Signing

```swift
import CryptoSwift

// Add your private key
let privateKey = EthPrivateKey(
        hex: "YOUR_PRIVATE_KEY"
)

// Form the bytes for your message
// In our example we sign null Ethereum address
let messageBytes = try! EthAddress(
        hex: "0x0000000000000000000000000000000000000000"
).value().bytes

// Create a message
// Don't forget that some services may expect
// a message with Ethereum prefix as here
let message = ConcatenatedBytes(
        bytes: [
            //Ethereum prefix
            UTF8StringBytes(
                    string: SimpleString(
                            string: "\u{19}Ethereum Signed Message:\n32"
                    )
            ),
            //message
            Keccak256Bytes(
                    origin: SimpleBytes(
                            bytes:
                    )
            )
        ]
)

// Use your custom hash function if needed
let hashFunction = SHA3(variant: .keccak256).calculate

// Create the signature
// Calculations are performed in a lazy way
// so you don't have to worry about performance
let signature = SECP256k1Signature(
        privateKey: privateKey,
        message: message,
        hashFunction: hashFunction
)

// Now you can retrieve all the parameters
// of the signature or use it for the signing with web3
let r = PrefixedHexString(
        bytes: try! signature.r()
)
let s = PrefixedHexString(
        bytes: try! signature.s()
)
let v = try! signature.recoverID().value() + 27
```

## Parsing transactions
### Fetching information about transactions
Getting results of the recent or previous transaction is one of the most common tasks during developing interactions with DApps. There are two JSON-RPC methods for getting basic and additional transaction info. The first one is `eth_getTransactionByHash` ([example](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionbyhash)) and the second one is `eth_getTransactionReceipt`([example](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionreceipt)). You could use next library example to get needed information from the Ethereum blockchain.
```swift
import Web3Swift
import CryptoSwift

let transactionHash = BytesFromHexString(
    hex: "0x5798fbc45e3b63832abc4984b0f3574a13545f415dd672cd8540cd71f735db56"
)

let network = InfuraNetwork(
    chain: "mainnet",
    apiKey: "metamask"
)

let basicInfo: JSON = try TransactionProcedure(
    network: network,
    transactionHash: transactionHash
).call()

let advancedInfo: JSON = try TransactionReceiptProcedure(
    network: network,
    transactionHash: transactionHash
).call()

print(basicInfo["result"].dictionary ?? "Something went wrong")
/**
[
    "blockNumber": 0x196666,
    "value": 0x0,
    "v": 0x1b,
    "input":0x612e45a3000000000000000000000000b656b2a9c3b2416437a811e07466ca712f5a5b5a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000093a80000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000116c6f6e656c792c20736f206c6f6e656c7900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
    "hash": 0x5798fbc45e3b63832abc4984b0f3574a13545f415dd672cd8540cd71f735db56,
    "to": 0xbb9bc244d798123fde783fcc1c72d3bb8c189413,
    "transactionIndex": 0x7,
    "gasPrice": 0x4a817c800,
    "r": 0xd92d67e4a982c45c78c1260fc2f644ed78483e2bf7d6151aab9ea40a8e172472,
    "nonce": 0x0,
    "blockHash": 0x1f716531f40858da4d4b08269f571f9f22c7b8bd921764e8bdf9cb2e0508efa1,
    "from": 0xb656b2a9c3b2416437a811e07466ca712f5a5b5a,
    "s": 0x6ee7e259e4f13378cf167bb980659520a7e5897643a2642586f246c6de5367d6,
    "gas": 0x4c449
]
*/

print(advancedInfo["result"].dictionary ?? "Something went wrong")

/**
[
    "root": 0xee69c77c73cd53b90e928e786b1c7f5b743a36dccd877128cf1dce7b46980a97,
    "blockNumber": 0x196666,
    "transactionIndex": 0x7,
    "transactionHash": 0x5798fbc45e3b63832abc4984b0f3574a13545f415dd672cd8540cd71f735db56,
    "blockHash": 0x1f716531f40858da4d4b08269f571f9f22c7b8bd921764e8bdf9cb2e0508efa1,
    "from": 0xb656b2a9c3b2416437a811e07466ca712f5a5b5a,
    "contractAddress": null,
    "logsBloom": 0x00000000000000020000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000200000000000000000000800000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000,
    "to": 0xbb9bc244d798123fde783fcc1c72d3bb8c189413,
    "logs": [
        {
            "blockNumber" : "0x196666",
            "topics" : [
                "0x5790de2c279e58269b93b12828f56fd5f2bc8ad15e61ce08572585c81a38756f",
                "0x000000000000000000000000000000000000000000000000000000000000003b"
            ],
            "data" : "0x000000000000000000000000b656b2a9c3b2416437a811e07466ca712f5a5b5a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000116c6f6e656c792c20736f206c6f6e656c79000000000000000000000000000000",
            "logIndex" : "0x5",
            "transactionHash" : "0x5798fbc45e3b63832abc4984b0f3574a13545f415dd672cd8540cd71f735db56",
            "removed" : false,
            "address" : "0xbb9bc244d798123fde783fcc1c72d3bb8c189413",
            "blockHash" : "0x1f716531f40858da4d4b08269f571f9f22c7b8bd921764e8bdf9cb2e0508efa1",
            "transactionIndex" : "0x7"
        }
    ],
    "gasUsed": 0x33da9,
    "cumulativeGasUsed": 0xf98e3
]
*/
```
**NOTE:** Library is still in development. Domain level objects for all RPC structures are on the roadmap.

## Author

- Timofey Solonin [@biboran](https://github.com/biboran), abdulowork@gmail.com
- Vadim Koleoshkin [@rockfridrich](https://github.com/rockfridrich), vadim@zerion.io

## License

Web3Swift is available under the Apache License 2.0. See the LICENSE file for more info.
