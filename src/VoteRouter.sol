// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

contract VoteRouter{

    enum Vote{ FOR, AGAINST } // Creating enums to denote two types of vote 

    struct VoteCount{
        uint256 forVotes;
        uint256 againstVotes;
    }

    mapping(uint256 => VoteCount) public votes;

    // variables to store important contract addresses and domain identifiers
    address mailbox;
    uint32 domainId;
    address voteContract;

    // Modifier so that only mailbox can call particular functions
    modifier onlyMailbox(){
        require(msg.sender == mailbox, "Only mailbox can call this function !!!");
        _;
    }

    constructor(address _mailbox, uint32 _domainId, address _voteContract){
        mailbox = _mailbox;
        domainId = _domainId;
        voteContract = _voteContract;
    }

    // By calling this function you can cast your vote on other chain
    function sendVote(uint256 _proposalId, Vote _voteType) payable external {
        bytes memory data = abi.encode(1,abi.encode(_proposalId,msg.sender,_voteType));
        uint256 quote = IMailbox(mailbox).quoteDispatch(domainId, addressToBytes32(voteContract), data);
        IMailbox(mailbox).dispatch{value: quote}(domainId, addressToBytes32(voteContract), data);
    }

    // By calling this function you can fetch votes from the main contract
    function fetchVotes(uint256 _proposalId) payable external{
        bytes memory data = abi.encode(2,abi.encode(_proposalId));
        uint256 quote = IMailbox(mailbox).quoteDispatch(domainId, addressToBytes32(voteContract), data);
        IMailbox(mailbox).dispatch{value: quote}(domainId, addressToBytes32(voteContract), data);
    }

    // handle function which is called by the mailbox to bridge votes from other chains
    function handle(uint32 _origin, bytes32 _sender, bytes memory _body) external onlyMailbox{
        (uint256 proposalId, uint256 forVotes, uint256 againstVotes) = abi.decode(_body, (uint256, uint256, uint256));
        votes[proposalId].forVotes = forVotes;
        votes[proposalId].againstVotes = againstVotes;
    }

    // function to get votes for a particular proposal
    function getVotes(uint256 _proposalId) public view returns(uint256 _for, uint256 _against){
        _for = votes[_proposalId].forVotes;
        _against = votes[_proposalId].againstVotes;
    }

    // converts address to bytes32
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    receive() external payable{}

}
