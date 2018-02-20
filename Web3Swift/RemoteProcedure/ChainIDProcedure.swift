//
//  ChainIDProcedure.swift
//  CryptoSwift
//
//  Created by Timofey on 2/1/18.
//

import Foundation
import SwiftyJSON

public final class ChainIDProcedure: RemoteProcedure {

    private let network: Network

    init(network: Network) {
        self.network = network
    }

    public func call() throws -> JSON {
        return try JSON(
            data: network.call(
                method: "net_version",
                params: []
            )
        )
    }

}