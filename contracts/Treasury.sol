pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import {
SafeERC20,
IERC20,
Address
} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract Treasury is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    address public governance;
    address public pendingGovernance;

    event RetrieveToken (address token, uint amount);
    event RetrieveETH (uint amount);
    event PendingGovernance (address newPendingGov);
    event AcceptedGovernance (address newGov);
    event FailedETHSend(bytes returnedData);

    receive() external payable {}

    constructor() public {
        governance = msg.sender;
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }

    function setGovernance(address _newGov) external onlyGovernance {
        require(_newGov != address(0));
        pendingGovernance = _newGov;
        emit PendingGovernance(_newGov);
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pendingGovernance");
        governance = pendingGovernance;
        pendingGovernance = address(0);
        emit AcceptedGovernance(governance);
    }

    //Retrieve full balance of token in contract
    function retrieveToken(address _token) external onlyGovernance {
        retrieveTokenExact(_token, IERC20(_token).balanceOf(address(this)));
    }

    function retrieveTokenExact(address _token, uint _amount) public onlyGovernance {
        IERC20(_token).safeTransfer(governance, _amount);
        emit RetrieveToken(_token, _amount);
    }

    function retrieveETH() external onlyGovernance {
        retrieveETHExact(address(this).balance);
    }

    function retrieveETHExact(uint _amount) public onlyGovernance nonReentrant {
        (bool success, bytes memory returnData) = governance.call{value : _amount}("");
        require(success, "Sending ETH failed");
        emit RetrieveETH(_amount);
    }

}
