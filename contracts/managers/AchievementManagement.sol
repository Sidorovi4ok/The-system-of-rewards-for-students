// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IStudentRewards.sol";

contract AchievementManagement is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TEACHER_ROLE = keccak256("TEACHER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    struct Achievement {
        address student;
        uint8 scale;  // 4 - международные, 3 - всероссийские, 2 - областные, 1 - городские
        uint8 place;  // 4 - 1 место, 3 - 2 место, 2 - 3 место, 1 - другое
        uint32 points;
        string description;
        uint256 timestamp;
    }

    mapping(uint256 => Achievement) public achievements;
    mapping(address => uint256[]) public studentAchievements;
    uint256 private _achievementCounter;

    event AchievementAdded(address indexed student, uint8 scale, uint8 place, uint32 points);
    event AchievementUpdated(uint256 indexed achievementId, uint8 scale, uint8 place, uint32 points);
    event AchievementRemoved(uint256 indexed achievementId);

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "AchievementManagement: caller is not an admin");
        _;
    }

    modifier onlyTeacher() {
        require(hasRole(TEACHER_ROLE, msg.sender), "AchievementManagement: caller is not a teacher");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function addAchievement(
        address student,
        uint8 scale,
        uint8 place,
        string memory description
    ) external onlyTeacher whenNotPaused {
        require(hasRole(STUDENT_ROLE, student), "AchievementManagement: recipient is not a student");
        require(scale >= 1 && scale <= 4, "AchievementManagement: invalid scale");
        require(place >= 1 && place <= 4, "AchievementManagement: invalid place");

        uint32 points = uint32(scale * place);
        uint256 achievementId = _achievementCounter++;

        achievements[achievementId] = Achievement({
            student: student,
            scale: scale,
            place: place,
            points: points,
            description: description,
            timestamp: block.timestamp
        });

        studentAchievements[student].push(achievementId);

        emit AchievementAdded(student, scale, place, points);
    }

    function updateAchievement(
        uint256 achievementId,
        uint8 scale,
        uint8 place,
        string memory description
    ) external onlyTeacher whenNotPaused {
        require(achievements[achievementId].student != address(0), "AchievementManagement: achievement does not exist");
        require(scale >= 1 && scale <= 4, "AchievementManagement: invalid scale");
        require(place >= 1 && place <= 4, "AchievementManagement: invalid place");

        Achievement storage achievement = achievements[achievementId];
        achievement.scale = scale;
        achievement.place = place;
        achievement.points = uint32(scale * place);
        achievement.description = description;

        emit AchievementUpdated(achievementId, scale, place, achievement.points);
    }

    function removeAchievement(uint256 achievementId) external onlyAdmin whenNotPaused {
        require(achievements[achievementId].student != address(0), "AchievementManagement: achievement does not exist");
        
        address student = achievements[achievementId].student;
        uint256[] storage studentAch = studentAchievements[student];
        
        for (uint256 i = 0; i < studentAch.length; i++) {
            if (studentAch[i] == achievementId) {
                studentAch[i] = studentAch[studentAch.length - 1];
                studentAch.pop();
                break;
            }
        }

        delete achievements[achievementId];
        emit AchievementRemoved(achievementId);
    }

    function getStudentAchievements(address student) external view returns (uint256[] memory) {
        return studentAchievements[student];
    }

    function getAchievement(uint256 achievementId) external view returns (Achievement memory) {
        return achievements[achievementId];
    }

    function calculateStudentPoints(address student) external view returns (uint32) {
        uint256[] memory studentAch = studentAchievements[student];
        uint32 totalPoints = 0;

        for (uint256 i = 0; i < studentAch.length; i++) {
            totalPoints += achievements[studentAch[i]].points;
        }

        return totalPoints;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
} 