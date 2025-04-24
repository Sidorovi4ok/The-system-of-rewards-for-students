// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IStudentRewards.sol";
import "./libraries/ArrayUtils.sol";

contract StudentRewards is IStudentRewards, AccessControl, Pausable, ReentrancyGuard {
    using ArrayUtils for uint[];
    using ArrayUtils for address[];

    // Constants for gas optimization
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TEACHER_ROLE = keccak256("TEACHER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    // Storage variables
    mapping(uint256 => Reward) private _rewards;
    mapping(address => uint256) private _studentPoints;
    mapping(address => StudentReward[]) private _studentRewards;
    uint256 private _rewardCounter;

    // Events
    event RewardCreated(uint256 indexed rewardId, string name, uint256 points);
    event RewardUpdated(uint256 indexed rewardId, string name, uint256 points);
    event RewardDeactivated(uint256 indexed rewardId);
    event RewardAssigned(address indexed student, uint256 indexed rewardId, address indexed teacher);
    event PointsUpdated(address indexed student, uint256 newPoints);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // Modifiers
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "StudentRewards: caller is not an admin");
        _;
    }

    modifier onlyTeacher() {
        require(hasRole(TEACHER_ROLE, msg.sender), "StudentRewards: caller is not a teacher");
        _;
    }

    // External functions
    function createReward(
        string calldata name,
        string calldata description,
        uint256 points
    ) external override onlyAdmin whenNotPaused {
        require(bytes(name).length > 0, "StudentRewards: name cannot be empty");
        require(points > 0, "StudentRewards: points must be greater than 0");

        uint256 rewardId = _rewardCounter++;
        _rewards[rewardId] = Reward({
            id: rewardId,
            name: name,
            description: description,
            points: points,
            isActive: true
        });

        emit RewardCreated(rewardId, name, points);
    }

    function updateReward(
        uint256 rewardId,
        string calldata name,
        string calldata description,
        uint256 points
    ) external override onlyAdmin whenNotPaused {
        require(_rewards[rewardId].isActive, "StudentRewards: reward does not exist");
        require(bytes(name).length > 0, "StudentRewards: name cannot be empty");
        require(points > 0, "StudentRewards: points must be greater than 0");

        _rewards[rewardId].name = name;
        _rewards[rewardId].description = description;
        _rewards[rewardId].points = points;

        emit RewardUpdated(rewardId, name, points);
    }

    function deactivateReward(uint256 rewardId) external override onlyAdmin whenNotPaused {
        require(_rewards[rewardId].isActive, "StudentRewards: reward does not exist");
        _rewards[rewardId].isActive = false;
        emit RewardDeactivated(rewardId);
    }

    function assignReward(
        address student,
        uint256 rewardId,
        string calldata comment
    ) external override onlyTeacher whenNotPaused nonReentrant {
        require(hasRole(STUDENT_ROLE, student), "StudentRewards: recipient is not a student");
        require(_rewards[rewardId].isActive, "StudentRewards: reward does not exist");

        StudentReward memory newReward = StudentReward({
            rewardId: rewardId,
            timestamp: block.timestamp,
            teacher: msg.sender,
            comment: comment
        });

        _studentRewards[student].push(newReward);
        _studentPoints[student] += _rewards[rewardId].points;

        emit RewardAssigned(student, rewardId, msg.sender);
        emit PointsUpdated(student, _studentPoints[student]);
    }

    // View functions
    function getReward(uint256 rewardId) external view override returns (Reward memory) {
        return _rewards[rewardId];
    }

    function getStudentRewards(address student) external view override returns (StudentReward[] memory) {
        return _studentRewards[student];
    }

    function getStudentPoints(address student) external view override returns (uint256) {
        return _studentPoints[student];
    }

    // Admin functions
    function pause() external override onlyAdmin {
        _pause();
    }

    function unpause() external override onlyAdmin {
        _unpause();
    }
} 