// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OnePieceMint is VRFConsumerBaseV2Plus, ERC721, ERC721URIStorage {
    uint256 private s_tokenCounter;

    string[] internal characterTokenURIs = [
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmNp4sHf4ccqPpqMBUCSG1CpFwFR4D6kgHesxc1mLs75am",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmPHaFt55PeidgCuXe2kaeRYmLaBUPE1Y7Kg4tDyzapZHy",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmP9pC9JuUpKcnjUk8GBXEWVTGvK3FTjXL91Q3MJ2rhA16",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmSnNXo5hxrFnpbyBeb7jY7jhkm5eyknaCXtr8muk31AHK",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmarkkgDuBUcnqksatPzU8uNS4o6LTbEtuK43P7Jyth9NH"
    ];

    uint256 public s_subscriptionId;
    bytes32 private i_keyHash;
    uint32 private i_callbackGasLimit;
    uint16 private i_requestConfirmations = 3;
    uint32 private i_numWords = 1;

    mapping(uint256 => address) private requestIdToSender;
    mapping(address => uint256) private userCharacter;
    mapping(address => bool) public hasMinted;
    mapping(address => uint256) public s_addressToCharacter;
    mapping(address => uint256) public userTokenID;

    event NftRequested(uint256 requestId, address requester);
    event CharacterTraitDetermined(uint256 characterId);
    event NftMinted(uint256 characterId, address minter);

    constructor(
        address vrfCoordinatorV2Address,
        uint256 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2Address) ERC721("OnePiece NFT", "OPN") {
        s_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
    }

    function mintNFT(address recipient, uint256 characterId) internal {
        require(!hasMinted[recipient], "You have already minted your house NFT");

        uint256 tokenId = s_tokenCounter;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, characterTokenURIs[characterId]);

        s_addressToCharacter[recipient] = characterId;
        userTokenID[recipient] = tokenId;

        s_tokenCounter += 1;
        hasMinted[recipient] = true;

        emit NftMinted(characterId, recipient);
    }

    function requestNFT(uint256[5] memory answers) public {
        userCharacter[msg.sender] = determineCharacter(answers);

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: i_requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: i_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: false
                    })
                )
            })
        );
        requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address nftOwner = requestIdToSender[requestId];
        uint256 traitBasedCharacterId = userCharacter[nftOwner];

        uint256 randomValue = randomWords[0];
        uint256 randomCharacterId = (randomValue % 5);

        uint256 finalCharacterId = (traitBasedCharacterId + randomCharacterId) % 5;
        mintNFT(nftOwner, finalCharacterId);
    }

    function determineCharacter(uint256[5] memory answers) private returns (uint256) {
        uint256 characterId = 0;
        for (uint256 i = 0; i < 5; i++) {
            characterId += answers[i];
        }
        characterId = (characterId % 5) + 1;
        emit CharacterTraitDetermined(characterId);
        return characterId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        require(from == address(0) || to == address(0), "Err! This is not allowed");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}