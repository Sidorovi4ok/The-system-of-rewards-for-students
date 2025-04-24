// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IStudentRewards.sol";

contract UserManagement is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TEACHER_ROLE = keccak256("TEACHER_ROLE");
    bytes32 public constant MERCHANDISER_ROLE = keccak256("MERCHANDISER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    mapping(address => IStudentRewards.User) public users;
    mapping(address => bool) public isLoggedIn;
    mapping(bytes32 => address) public loginToAddress;

    event UserCreated(address indexed userAddress, bytes32 login, string fio, IStudentRewards.Role role);
    event UserLoggedIn(address indexed userAddress);
    event UserLoggedOut(address indexed userAddress);
    event UserProfileUpdated(address indexed userAddress);
    event PasswordChanged(address indexed userAddress);

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    modifier userExists(address userAddress) {
        require(users[userAddress].role != IStudentRewards.Role.NONE, "User does not exist");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function createUser(
        address userAddress,
        bytes32 login,
        bytes32 phone,
        bytes32 email,
        string memory fio,
        bytes32 password,
        IStudentRewards.Role role,
        IStudentRewards.Gender gender
    ) external onlyAdmin whenNotPaused {
        require(userAddress != address(0), "Invalid address");
        require(loginToAddress[login] == address(0), "Login already exists");
        require(role != IStudentRewards.Role.NONE, "Invalid role");

        users[userAddress] = IStudentRewards.User({
            login: login,
            phone: phone,
            email: email,
            fio: fio,
            password: password,
            role: role,
            gender: gender,
            isActive: true
        });

        loginToAddress[login] = userAddress;
        _setupRole(roleToBytes32(role), userAddress);

        emit UserCreated(userAddress, login, fio, role);
    }

    function login(bytes32 login, bytes32 password) external whenNotPaused {
        address userAddress = loginToAddress[login];
        require(userAddress != address(0), "User not found");
        require(users[userAddress].password == password, "Invalid password");
        require(!isLoggedIn[userAddress], "User already logged in");

        isLoggedIn[userAddress] = true;
        emit UserLoggedIn(userAddress);
    }

    function logout() external {
        require(isLoggedIn[msg.sender], "User not logged in");
        isLoggedIn[msg.sender] = false;
        emit UserLoggedOut(msg.sender);
    }

    function updateUserProfile(
        bytes32 phone,
        bytes32 email,
        string memory fio
    ) external userExists(msg.sender) whenNotPaused {
        IStudentRewards.User storage user = users[msg.sender];
        user.phone = phone;
        user.email = email;
        user.fio = fio;
        emit UserProfileUpdated(msg.sender);
    }

    function changePassword(bytes32 newPassword) external userExists(msg.sender) whenNotPaused {
        users[msg.sender].password = newPassword;
        emit PasswordChanged(msg.sender);
    }

    function getUser(address userAddress) external view returns (IStudentRewards.User memory) {
        return users[userAddress];
    }

    function roleToBytes32(IStudentRewards.Role role) internal pure returns (bytes32) {
        if (role == IStudentRewards.Role.ADMIN) return ADMIN_ROLE;
        if (role == IStudentRewards.Role.TEACHER) return TEACHER_ROLE;
        if (role == IStudentRewards.Role.MERCHANDISER) return MERCHANDISER_ROLE;
        if (role == IStudentRewards.Role.STUDENT) return STUDENT_ROLE;
        revert("Invalid role");
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
} 