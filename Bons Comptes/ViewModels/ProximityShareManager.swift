//
//  ProximityShareManager.swift
//  Bons Comptes
//

import Foundation
import MultipeerConnectivity
import Combine

@MainActor
class ProximityShareManager: NSObject, ObservableObject {
    static let serviceType = "bonscomptes"

    enum State: Equatable {
        case idle
        case searching
        case connecting(String)
        case sending
        case receiving
        case completed(Bool) // true = received, false = sent
        case failed(String)
    }

    @Published var state: State = .idle
    @Published var nearbyPeers: [MCPeerID] = []
    @Published var receivedCampaignData: String?

    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var dataToSend: Data?

    override init() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    func startSharing(campaignData: String) {
        stop()
        state = .searching
        dataToSend = campaignData.data(using: .utf8)

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        // Advertise as sender
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["role": "sender"], serviceType: Self.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        // Also browse for receivers
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }

    func startReceiving() {
        stop()
        state = .searching

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        // Advertise as receiver
        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["role": "receiver"], serviceType: Self.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        // Also browse for senders
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        nearbyPeers = []
        state = .idle
        dataToSend = nil
        receivedCampaignData = nil
    }
}

// MARK: - MCSessionDelegate
extension ProximityShareManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if let data = self.dataToSend {
                    self.state = .sending
                    do {
                        try session.send(data, toPeers: [peerID], with: .reliable)
                        self.state = .completed(false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.stop() }
                    } catch {
                        self.state = .failed(error.localizedDescription)
                    }
                } else {
                    self.state = .receiving
                }
            case .connecting:
                self.state = .connecting(peerID.displayName)
            case .notConnected:
                if case .completed = self.state { return }
                // Don't reset if we just completed
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            if let str = String(data: data, encoding: .utf8) {
                self.receivedCampaignData = str
                self.state = .completed(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.stop() }
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ProximityShareManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ProximityShareManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            if !self.nearbyPeers.contains(peerID) {
                self.nearbyPeers.append(peerID)
            }
            // Auto-connect: sender invites receiver and vice versa
            if let session = self.session {
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.nearbyPeers.removeAll { $0 == peerID }
        }
    }
}
