// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IStudentRewards.sol";

/**
 * @title RewardManager
 * @dev Manages the creation, assignment, and tracking of student rewards
 */
contract RewardManager is AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using IStudentRewards for IStudentRewards.Role;

    // Constants for gas optimization
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TEACHER_ROLE = keccak256("TEACHER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    // Storage variables
    mapping(uint256 => IStudentRewards.Reward) private _rewards;
    mapping(address => uint256) private _studentPoints;
    mapping(address => IStudentRewards.StudentReward[]) private _studentRewards;
    mapping(address => EnumerableSet.UintSet) private _studentRewardIds;
    Counters.Counter private _rewardCounter;

    // Events
    event RewardCreated(uint256 indexed rewardId, string name, uint256 points);
    event RewardUpdated(uint256 indexed rewardId, string name, uint256 points);
    event RewardDeactivated(uint256 indexed rewardId);
    event RewardAssigned(address indexed student, uint256 indexed rewardId, address indexed teacher);
    event PointsUpdated(address indexed student, uint256 newPoints);

    /**
     * @dev Constructor sets up the initial admin role
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Modifier to restrict access to admin only
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "RewardManager: caller is not an admin");
        _;
    }

    /**
     * @dev Modifier to restrict access to teachers only
     */
    modifier onlyTeacher() {
        require(hasRole(TEACHER_ROLE, msg.sender), "RewardManager: caller is not a teacher");
        _;
    }

    /**
     * @dev Creates a new reward
     * @param name Name of the reward
     * @param description Description of the reward
     * @param points Points awarded for this reward
     */
    function createReward(
        string calldata name,
        string calldata description,
        uint256 points
    ) external onlyAdmin whenNotPaused {
        require(bytes(name).length > 0, "RewardManager: name cannot be empty");
        require(points > 0, "RewardManager: points must be greater than 0");

        uint256 rewardId = _rewardCounter.current();
        _rewardCounter.increment();

        _rewards[rewardId] = IStudentRewards.Reward({
            id: rewardId,
            name: name,
            description: description,
            points: points,
            isActive: true
        });

        emit RewardCreated(rewardId, name, points);
    }

    /**
     * @dev Updates an existing reward
     * @param rewardId ID of the reward to update
     * @param name New name for the reward
     * @param description New description for the reward
     * @param points New points value for the reward
     */
    function updateReward(
        uint256 rewardId,
        string calldata name,
        string calldata description,
        uint256 points
    ) external onlyAdmin whenNotPaused {
        require(_rewards[rewardId].isActive, "RewardManager: reward does not exist");
        require(bytes(name).length > 0, "RewardManager: name cannot be empty");
        require(points > 0, "RewardManager: points must be greater than 0");

        _rewards[rewardId].name = name;
        _rewards[rewardId].description = description;
        _rewards[rewardId].points = points;

        emit RewardUpdated(rewardId, name, points);
    }

    /**
     * @dev Deactivates a reward
     * @param rewardId ID of the reward to deactivate
     */
    function deactivateReward(uint256 rewardId) external onlyAdmin whenNotPaused {
        require(_rewards[rewardId].isActive, "RewardManager: reward does not exist");
        _rewards[rewardId].isActive = false;
        emit RewardDeactivated(rewardId);
    }

    /**
     * @dev Assigns a reward to a student
     * @param student Address of the student
     * @param rewardId ID of the reward to assign
     * @param comment Additional comment about the assignment
     */
    function assignReward(
        address student,
        uint256 rewardId,
        string calldata comment
    ) external onlyTeacher whenNotPaused nonReentrant {
        require(hasRole(STUDENT_ROLE, student), "RewardManager: recipient is not a student");
        require(_rewards[rewardId].isActive, "RewardManager: reward does not exist");

        IStudentRewards.StudentReward memory newReward = IStudentRewards.StudentReward({
            rewardId: rewardId,
            timestamp: block.timestamp,
            teacher: msg.sender,
            comment: comment
        });

        _studentRewards[student].push(newReward);
        _studentRewardIds[student].add(rewardId);
        _studentPoints[student] += _rewards[rewardId].points;

        emit RewardAssigned(student, rewardId, msg.sender);
        emit PointsUpdated(student, _studentPoints[student]);
    }

    /**
     * @dev Gets information about a specific reward
     * @param rewardId ID of the reward to get
     * @return Reward information
     */
    function getReward(uint256 rewardId) external view returns (IStudentRewards.Reward memory) {
        return _rewards[rewardId];
    }

    /**
     * @dev Gets all rewards assigned to a student
     * @param student Address of the student
     * @return Array of student rewards
     */
    function getStudentRewards(address student) external view returns (IStudentRewards.StudentReward[] memory) {
        return _studentRewards[student];
    }

    /**
     * @dev Gets the total points for a student
     * @param student Address of the student
     * @return Total points
     */
    function getStudentPoints(address student) external view returns (uint256) {
        return _studentPoints[student];
    }

    /**
     * @dev Gets all reward IDs assigned to a student
     * @param student Address of the student
     * @return Array of reward IDs
     */
    function getStudentRewardIds(address student) external view returns (uint256[] memory) {
        return _studentRewardIds[student].values();
    }

    /**
     * @dev Checks if a student has a specific reward
     * @param student Address of the student
     * @param rewardId ID of the reward to check
     * @return True if the student has the reward
     */
    function hasStudentReward(address student, uint256 rewardId) external view returns (bool) {
        return _studentRewardIds[student].contains(rewardId);
    }

    /**
     * @dev Pauses all contract operations
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev Resumes all contract operations
     */
    function unpause() external onlyAdmin {
        _unpause();
    }
} 