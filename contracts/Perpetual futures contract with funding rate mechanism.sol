// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Perpetual Futures Contract with Funding Rate
 * @dev Allows users to open long/short positions with funding payments
 */
contract Project {
    struct Position {
        bool isLong;
        uint256 margin;
        uint256 size;
        uint256 entryPrice;
        uint256 lastFundingTime;
        address trader;
    }

    address public owner;
    uint256 public fundingRate; // e.g., 100 = 1% per hour
    uint256 public nextPositionId;

    mapping(uint256 => Position) public positions;

    event PositionOpened(
        uint256 indexed positionId,
        address indexed trader,
        bool isLong,
        uint256 margin,
        uint256 size,
        uint256 entryPrice
    );

    event PositionClosed(
        uint256 indexed positionId,
        address indexed trader,
        uint256 pnl
    );

    constructor(uint256 _fundingRate) {
        owner = msg.sender;
        fundingRate = _fundingRate;
        nextPositionId = 1;
    }

    function setFundingRate(uint256 _rate) external {
        require(msg.sender == owner, "Only owner");
        fundingRate = _rate;
    }

    function openPosition(bool isLong, uint256 size) external payable {
        require(msg.value > 0, "Margin required");
        require(size > 0, "Size must be > 0");

        uint256 price = getPrice(); // mock price

        positions[nextPositionId] = Position({
            isLong: isLong,
            margin: msg.value,
            size: size,
            entryPrice: price,
            lastFundingTime: block.timestamp,
            trader: msg.sender
        });

        emit PositionOpened(
            nextPositionId,
            msg.sender,
            isLong,
            msg.value,
            size,
            price
        );

        nextPositionId++;
    }

    function closePosition(uint256 positionId) external {
        Position storage pos = positions[positionId];
        require(pos.trader == msg.sender, "Not position owner");

        uint256 currentPrice = getPrice();
        uint256 pnl = calculatePnL(pos, currentPrice);
        int256 fundingPayment = calculateFundingPayment(pos);

        delete positions[positionId];

        int256 total = int256(pos.margin) + int256(pnl) - fundingPayment;
        require(total >= 0, "Position loss exceeds margin");

        payable(msg.sender).transfer(uint256(total));

        emit PositionClosed(positionId, msg.sender, uint256(total));
    }

    function calculatePnL(Position memory pos, uint256 currentPrice) internal pure returns (uint256) {
        if (pos.isLong) {
            return (currentPrice > pos.entryPrice)
                ? (currentPrice - pos.entryPrice) * pos.size / pos.entryPrice
                : 0;
        } else {
            return (pos.entryPrice > currentPrice)
                ? (pos.entryPrice - currentPrice) * pos.size / pos.entryPrice
                : 0;
        }
    }

    function calculateFundingPayment(Position memory pos) internal view returns (int256) {
        uint256 elapsedHours = (block.timestamp - pos.lastFundingTime) / 1 hours;
        if (elapsedHours == 0) return 0;

        int256 payment = int256(fundingRate) * int256(elapsedHours) * int256(pos.size) / 10000;
        return payment;
    }

    function getPrice() public view returns (uint256) {
        // For demo, return dummy price
        return 1000 * 1e18;
    }

    receive() external payable {}
}
