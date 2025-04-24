// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IStudentRewards
 * @dev Interface for the student rewards system
 */
interface IStudentRewards {
    /**
     * @dev Enum for user roles in the system
     */
    enum Role {
        NONE,
        ADMIN,
        TEACHER,
        STUDENT
    }

    /**
     * @dev Enum for user gender
     */
    enum Gender {
        MALE,
        FEMALE
    }

    /**
     * @dev Struct for user information
     * @param login User's login (hashed)
     * @param phone User's phone number (hashed)
     * @param email User's email (hashed)
     * @param fio User's full name
     * @param password User's password (hashed)
     * @param role User's role in the system
     * @param gender User's gender
     * @param isActive Whether the user account is active
     */
    struct User {
        bytes32 login;
        bytes32 phone;
        bytes32 email;
        string fio;
        bytes32 password;
        Role role;
        Gender gender;
        bool isActive;
    }

    /**
     * @dev Struct for reward information
     * @param id Unique identifier for the reward
     * @param name Name of the reward
     * @param description Description of the reward
     * @param points Points awarded for this reward
     * @param isActive Whether the reward is active
     */
    struct Reward {
        uint256 id;
        string name;
        string description;
        uint256 points;
        bool isActive;
    }

    /**
     * @dev Struct for student reward assignment
     * @param rewardId ID of the assigned reward
     * @param timestamp Time when the reward was assigned
     * @param teacher Address of the teacher who assigned the reward
     * @param comment Additional comment about the reward assignment
     */
    struct StudentReward {
        uint256 rewardId;
        uint256 timestamp;
        address teacher;
        string comment;
    }

    /**
     * @dev Emitted when a new reward is created
     * @param rewardId ID of the created reward
     * @param name Name of the reward
     * @param points Points awarded for this reward
     */
    event RewardCreated(uint256 indexed rewardId, string name, uint256 points);

    /**
     * @dev Emitted when a reward is updated
     * @param rewardId ID of the updated reward
     * @param name New name of the reward
     * @param points New points value for the reward
     */
    event RewardUpdated(uint256 indexed rewardId, string name, uint256 points);

    /**
     * @dev Emitted when a reward is deactivated
     * @param rewardId ID of the deactivated reward
     */
    event RewardDeactivated(uint256 indexed rewardId);

    /**
     * @dev Emitted when a reward is assigned to a student
     * @param student Address of the student
     * @param rewardId ID of the assigned reward
     * @param teacher Address of the teacher who assigned the reward
     */
    event RewardAssigned(address indexed student, uint256 indexed rewardId, address indexed teacher);

    /**
     * @dev Emitted when a student's points are updated
     * @param student Address of the student
     * @param newPoints New total points for the student
     */
    event PointsUpdated(address indexed student, uint256 newPoints);

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
    ) external;

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
    ) external;

    /**
     * @dev Deactivates a reward
     * @param rewardId ID of the reward to deactivate
     */
    function deactivateReward(uint256 rewardId) external;

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
    ) external;

    /**
     * @dev Gets information about a specific reward
     * @param rewardId ID of the reward to get
     * @return Reward information
     */
    function getReward(uint256 rewardId) external view returns (Reward memory);

    /**
     * @dev Gets all rewards assigned to a student
     * @param student Address of the student
     * @return Array of student rewards
     */
    function getStudentRewards(address student) external view returns (StudentReward[] memory);

    /**
     * @dev Gets the total points for a student
     * @param student Address of the student
     * @return Total points
     */
    function getStudentPoints(address student) external view returns (uint256);

    /**
     * @dev Pauses all contract operations
     */
    function pause() external;

    /**
     * @dev Resumes all contract operations
     */
    function unpause() external;

    // Функции
    function createUser(
        address addr,
        bytes32 login,
        bytes32 phone,
        bytes32 email,
        string memory fio,
        bytes32 password,
        bytes32 role,
        bool gender
    ) external;

    function createStudent(
        address addr,
        bytes32 group,
        bytes32 speciality,
        uint8 course
    ) external;

    function login(bytes32 password) external;
    function logout() external;
    function updateUserProfile(bytes32 phone, bytes32 email, string memory fio) external;
    function changePassword(bytes32 newPassword) external;

    function createProduct(
        bytes32 name,
        string memory description,
        Category category,
        uint32 amount,
        uint32 price
    ) external;

    function buyProduct(uint id) external;
    function addAchievement(address student, uint8 scale, uint8 place, string memory description) external;
    function updateStudentRewards() external;
    function getTopStudents(uint limit) external view returns (address[] memory, uint32[] memory);
    function advanceCourse() external;
} 