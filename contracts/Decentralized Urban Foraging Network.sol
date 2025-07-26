// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract UrbanForagingNetwork {
    struct ForagingLocation {
        uint256 id;
        address owner;
        string name;
        string description;
        string coordinates;
        uint256 accessFee;
        bool isActive;
        uint256 harvestLimit;
        uint256 currentHarvested;
        uint256 seasonStartTime;
        uint256 seasonEndTime;
    }
    
    struct ForagingSession {
        uint256 locationId;
        address forager;
        uint256 harvestedAmount;
        uint256 timestamp;
        bool verified;
    }
    
    mapping(uint256 => ForagingLocation) public foragingLocations;
    mapping(address => uint256[]) public ownerLocations;
    mapping(address => uint256) public foragingTokenBalance;
    mapping(uint256 => ForagingSession[]) public locationSessions;
    
    uint256 public nextLocationId = 1;
    uint256 public constant TOKENS_PER_HARVEST = 10;
    uint256 public constant OWNER_REWARD_PERCENTAGE = 70;
    
    event LocationRegistered(uint256 indexed locationId, address indexed owner, string name);
    event ForagingSessionCompleted(uint256 indexed locationId, address indexed forager, uint256 harvestedAmount);
    event TokensEarned(address indexed user, uint256 amount);
    event HarvestLimitUpdated(uint256 indexed locationId, uint256 newLimit);
    event ForagingSessionVerified(uint256 indexed locationId, uint256 sessionIndex);

    function registerForagingLocation(
        string memory _name,
        string memory _description,
        string memory _coordinates,
        uint256 _accessFee,
        uint256 _harvestLimit,
        uint256 _seasonDuration
    ) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_harvestLimit > 0, "Harvest limit must be greater than 0");
        
        foragingLocations[nextLocationId] = ForagingLocation({
            id: nextLocationId,
            owner: msg.sender,
            name: _name,
            description: _description,
            coordinates: _coordinates,
            accessFee: _accessFee,
            isActive: true,
            harvestLimit: _harvestLimit,
            currentHarvested: 0,
            seasonStartTime: block.timestamp,
            seasonEndTime: block.timestamp + _seasonDuration
        });
        
        ownerLocations[msg.sender].push(nextLocationId);
        
        emit LocationRegistered(nextLocationId, msg.sender, _name);
        nextLocationId++;
    }
    
    function conductForagingSession(
        uint256 _locationId,
        uint256 _harvestedAmount
    ) external payable {
        require(_locationId < nextLocationId, "Location does not exist");
        ForagingLocation storage location = foragingLocations[_locationId];
        
        require(location.isActive, "Location is not active");
        require(block.timestamp >= location.seasonStartTime && block.timestamp <= location.seasonEndTime, "Not in foraging season");
        require(location.currentHarvested + _harvestedAmount <= location.harvestLimit, "Exceeds harvest limit");
        require(msg.value >= location.accessFee, "Insufficient access fee");
        
        location.currentHarvested += _harvestedAmount;
        
        locationSessions[_locationId].push(ForagingSession({
            locationId: _locationId,
            forager: msg.sender,
            harvestedAmount: _harvestedAmount,
            timestamp: block.timestamp,
            verified: false
        }));
        
        uint256 tokensEarned = _harvestedAmount * TOKENS_PER_HARVEST;
        uint256 ownerReward = (tokensEarned * OWNER_REWARD_PERCENTAGE) / 100;
        uint256 foragerReward = tokensEarned - ownerReward;
        
        foragingTokenBalance[location.owner] += ownerReward;
        foragingTokenBalance[msg.sender] += foragerReward;
        
        payable(location.owner).transfer(msg.value);
        
        emit ForagingSessionCompleted(_locationId, msg.sender, _harvestedAmount);
        emit TokensEarned(location.owner, ownerReward);
        emit TokensEarned(msg.sender, foragerReward);
    }
    
    function updateHarvestLimit(uint256 _locationId, uint256 _newLimit) external {
        require(_locationId < nextLocationId, "Location does not exist");
        ForagingLocation storage location = foragingLocations[_locationId];
        require(msg.sender == location.owner, "Only owner can update harvest limit");
        require(_newLimit >= location.currentHarvested, "New limit cannot be less than current harvested amount");
        
        location.harvestLimit = _newLimit;
        emit HarvestLimitUpdated(_locationId, _newLimit);
    }
    
    function extendForagingSeason(uint256 _locationId, uint256 _additionalTime) external {
        require(_locationId < nextLocationId, "Location does not exist");
        ForagingLocation storage location = foragingLocations[_locationId];
        require(msg.sender == location.owner, "Only owner can extend season");
        
        location.seasonEndTime += _additionalTime;
    }

    function verifyForagingSession(uint256 _locationId, uint256 _sessionIndex) external {
        require(_locationId < nextLocationId, "Location does not exist");
        ForagingLocation storage location = foragingLocations[_locationId];
        require(msg.sender == location.owner, "Only owner can verify session");
        require(_sessionIndex < locationSessions[_locationId].length, "Invalid session index");

        ForagingSession storage session = locationSessions[_locationId][_sessionIndex];
        require(!session.verified, "Session already verified");

        session.verified = true;

        emit ForagingSessionVerified(_locationId, _sessionIndex);
    }
    
    function getLocationDetails(uint256 _locationId) external view returns (
        string memory name,
        string memory description,
        string memory coordinates,
        uint256 accessFee,
        bool isActive,
        uint256 harvestLimit,
        uint256 currentHarvested,
        uint256 seasonEndTime
    ) {
        require(_locationId < nextLocationId, "Location does not exist");
        ForagingLocation memory location = foragingLocations[_locationId];
        
        return (
            location.name,
            location.description,
            location.coordinates,
            location.accessFee,
            location.isActive,
            location.harvestLimit,
            location.currentHarvested,
            location.seasonEndTime
        );
    }
}
"added one function suggested by Chatgpt"
