# Foundry Smart Contract Testing Template

## Overview
This template provides comprehensive patterns for testing smart contracts using Foundry, covering testing patterns, coverage requirements, deployment testing, and integration with our NX monorepo structure.

## Foundry Project Setup

### Project Configuration
```toml
# libs/blockchain/contracts/foundry.toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
test = "test"
cache_path = "cache"

# Compiler settings
solc_version = "0.8.19"
optimizer = true
optimizer_runs = 200
via_ir = false

# Testing settings
verbosity = 2
fuzz_runs = 1000
fuzz_max_test_rejects = 65536

# Gas reporting
gas_reports = ["*"]
gas_reports_ignore = ["test/**/*"]

# Coverage settings
coverage = true
coverage_exclude = ["test/**/*", "script/**/*"]

[profile.ci]
fuzz_runs = 10000
verbosity = 4

[profile.test]
src = "src"
test = "test"
verbosity = 3

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
sepolia = "${SEPOLIA_RPC_URL}"
polygon = "${POLYGON_RPC_URL}"
mumbai = "${MUMBAI_RPC_URL}"

[etherscan]
mainnet = { key = "${ETHERSCAN_API_KEY}" }
sepolia = { key = "${ETHERSCAN_API_KEY}" }
polygon = { key = "${POLYGONSCAN_API_KEY}" }
mumbai = { key = "${POLYGONSCAN_API_KEY}" }
```

### NX Integration
```json
// libs/blockchain/contracts/project.json
{
  "name": "blockchain-contracts",
  "sourceRoot": "libs/blockchain/contracts/src",
  "projectType": "library",
  "targets": {
    "build": {
      "executor": "nx:run-commands",
      "options": {
        "command": "forge build",
        "cwd": "libs/blockchain/contracts"
      }
    },
    "test": {
      "executor": "nx:run-commands",
      "options": {
        "command": "forge test -vvv",
        "cwd": "libs/blockchain/contracts"
      }
    },
    "test-coverage": {
      "executor": "nx:run-commands",
      "options": {
        "command": "forge coverage --report lcov",
        "cwd": "libs/blockchain/contracts"
      }
    },
    "test-gas": {
      "executor": "nx:run-commands",
      "options": {
        "command": "forge test --gas-report",
        "cwd": "libs/blockchain/contracts"
      }
    },
    "deploy-local": {
      "executor": "nx:run-commands",
      "options": {
        "command": "forge script script/Deploy.s.sol --fork-url http://localhost:8545 --broadcast",
        "cwd": "libs/blockchain/contracts"
      }
    },
    "deploy-testnet": {
      "executor": "nx:run-commands",
      "options": {
        "command": "forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify",
        "cwd": "libs/blockchain/contracts"
      }
    }
  },
  "tags": ["scope:blockchain", "type:contracts"]
}
```

## Smart Contract Testing Patterns

### Base Test Contract
```solidity
// libs/blockchain/contracts/test/BaseTest.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TaskManager.sol";

contract BaseTest is Test {
    TaskManager public taskManager;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public maliciousUser = address(0x4);
    
    uint256 public constant INITIAL_BALANCE = 100 ether;
    
    event TaskCreated(uint256 indexed taskId, address indexed owner, string title);
    event TaskUpdated(uint256 indexed taskId, string title, string description);
    event TaskCompleted(uint256 indexed taskId, uint256 completedAt);
    
    function setUp() public virtual {
        // Set up initial balances
        vm.deal(owner, INITIAL_BALANCE);
        vm.deal(user1, INITIAL_BALANCE);
        vm.deal(user2, INITIAL_BALANCE);
        vm.deal(maliciousUser, INITIAL_BALANCE);
        
        // Deploy contract as owner
        vm.prank(owner);
        taskManager = new TaskManager();
        
        // Label addresses for better trace output
        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(maliciousUser, "MaliciousUser");
        vm.label(address(taskManager), "TaskManager");
    }
    
    // Helper functions
    function createSampleTask(address user, string memory title) internal returns (uint256) {
        vm.prank(user);
        return taskManager.createTask(title, "Sample description", block.timestamp + 1 days);
    }
    
    function expectTaskCreatedEvent(uint256 taskId, address taskOwner, string memory title) internal {
        vm.expectEmit(true, true, false, true);
        emit TaskCreated(taskId, taskOwner, title);
    }
    
    function assertTaskExists(uint256 taskId, address expectedOwner, string memory expectedTitle) internal {
        (uint256 id, address taskOwner, string memory title, string memory description, bool completed, uint256 createdAt, uint256 dueDate) = taskManager.getTask(taskId);
        
        assertEq(id, taskId, "Task ID mismatch");
        assertEq(taskOwner, expectedOwner, "Task owner mismatch");
        assertEq(title, expectedTitle, "Task title mismatch");
        assertFalse(completed, "Task should not be completed");
        assertGt(createdAt, 0, "Created timestamp should be set");
        assertGt(dueDate, createdAt, "Due date should be after creation");
    }
}
```

### Unit Testing Patterns
```solidity
// libs/blockchain/contracts/test/TaskManager.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseTest.sol";

contract TaskManagerTest is BaseTest {
    
    function testCreateTask() public {
        string memory title = "Test Task";
        string memory description = "Test Description";
        uint256 dueDate = block.timestamp + 1 days;
        
        // Expect event emission
        expectTaskCreatedEvent(1, user1, title);
        
        // Create task
        vm.prank(user1);
        uint256 taskId = taskManager.createTask(title, description, dueDate);
        
        // Assertions
        assertEq(taskId, 1, "First task should have ID 1");
        assertTaskExists(taskId, user1, title);
        assertEq(taskManager.getTaskCount(), 1, "Task count should be 1");
    }
    
    function testCreateTaskWithEmptyTitle() public {
        vm.prank(user1);
        vm.expectRevert("Title cannot be empty");
        taskManager.createTask("", "Description", block.timestamp + 1 days);
    }
    
    function testCreateTaskWithPastDueDate() public {
        vm.prank(user1);
        vm.expectRevert("Due date must be in the future");
        taskManager.createTask("Title", "Description", block.timestamp - 1 days);
    }
    
    function testUpdateTask() public {
        // Create task first
        uint256 taskId = createSampleTask(user1, "Original Title");
        
        string memory newTitle = "Updated Title";
        string memory newDescription = "Updated Description";
        
        // Expect event emission
        vm.expectEmit(true, false, false, true);
        emit TaskUpdated(taskId, newTitle, newDescription);
        
        // Update task
        vm.prank(user1);
        taskManager.updateTask(taskId, newTitle, newDescription);
        
        // Verify update
        (, , string memory title, string memory description, , , ) = taskManager.getTask(taskId);
        assertEq(title, newTitle, "Title should be updated");
        assertEq(description, newDescription, "Description should be updated");
    }
    
    function testUpdateTaskUnauthorized() public {
        uint256 taskId = createSampleTask(user1, "Test Task");
        
        vm.prank(user2);
        vm.expectRevert("Only task owner can update");
        taskManager.updateTask(taskId, "New Title", "New Description");
    }
    
    function testCompleteTask() public {
        uint256 taskId = createSampleTask(user1, "Test Task");
        
        // Expect event emission
        vm.expectEmit(true, false, false, false);
        emit TaskCompleted(taskId, block.timestamp);
        
        // Complete task
        vm.prank(user1);
        taskManager.completeTask(taskId);
        
        // Verify completion
        (, , , , bool completed, , ) = taskManager.getTask(taskId);
        assertTrue(completed, "Task should be completed");
    }
    
    function testCompleteNonexistentTask() public {
        vm.prank(user1);
        vm.expectRevert("Task does not exist");
        taskManager.completeTask(999);
    }
    
    function testGetUserTasks() public {
        // Create multiple tasks for user1
        createSampleTask(user1, "Task 1");
        createSampleTask(user1, "Task 2");
        createSampleTask(user2, "Task 3");
        
        // Get user1's tasks
        uint256[] memory user1Tasks = taskManager.getUserTasks(user1);
        assertEq(user1Tasks.length, 2, "User1 should have 2 tasks");
        assertEq(user1Tasks[0], 1, "First task ID should be 1");
        assertEq(user1Tasks[1], 2, "Second task ID should be 2");
        
        // Get user2's tasks
        uint256[] memory user2Tasks = taskManager.getUserTasks(user2);
        assertEq(user2Tasks.length, 1, "User2 should have 1 task");
        assertEq(user2Tasks[0], 3, "Task ID should be 3");
    }
}
```

### Fuzz Testing Patterns
```solidity
// libs/blockchain/contracts/test/TaskManagerFuzz.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseTest.sol";

contract TaskManagerFuzzTest is BaseTest {
    
    function testFuzzCreateTask(
        string calldata title,
        string calldata description,
        uint256 dueDate
    ) public {
        // Bound inputs to valid ranges
        vm.assume(bytes(title).length > 0 && bytes(title).length <= 100);
        vm.assume(bytes(description).length <= 1000);
        dueDate = bound(dueDate, block.timestamp + 1, block.timestamp + 365 days);
        
        vm.prank(user1);
        uint256 taskId = taskManager.createTask(title, description, dueDate);
        
        // Verify task was created correctly
        assertGt(taskId, 0, "Task ID should be greater than 0");
        assertTaskExists(taskId, user1, title);
    }
    
    function testFuzzUpdateTask(
        string calldata originalTitle,
        string calldata newTitle,
        string calldata newDescription
    ) public {
        // Bound inputs
        vm.assume(bytes(originalTitle).length > 0 && bytes(originalTitle).length <= 100);
        vm.assume(bytes(newTitle).length > 0 && bytes(newTitle).length <= 100);
        vm.assume(bytes(newDescription).length <= 1000);
        
        // Create task
        uint256 taskId = createSampleTask(user1, originalTitle);
        
        // Update task
        vm.prank(user1);
        taskManager.updateTask(taskId, newTitle, newDescription);
        
        // Verify update
        (, , string memory title, string memory description, , , ) = taskManager.getTask(taskId);
        assertEq(title, newTitle, "Title should be updated");
        assertEq(description, newDescription, "Description should be updated");
    }
    
    function testFuzzMultipleUsers(address[] calldata users) public {
        // Bound array size
        vm.assume(users.length > 0 && users.length <= 10);
        
        // Create tasks for each user
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            vm.assume(user != address(0));
            
            vm.prank(user);
            uint256 taskId = taskManager.createTask(
                string(abi.encodePacked("Task ", i)),
                "Fuzz description",
                block.timestamp + 1 days
            );
            
            assertEq(taskId, i + 1, "Task ID should increment");
        }
        
        assertEq(taskManager.getTaskCount(), users.length, "Task count should match user count");
    }
}
```

### Integration Testing with Forking
```solidity
// libs/blockchain/contracts/test/TaskManagerIntegration.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseTest.sol";

contract TaskManagerIntegrationTest is BaseTest {
    
    function setUp() public override {
        // Fork mainnet for integration testing
        vm.createFork(vm.envString("MAINNET_RPC_URL"));
        
        super.setUp();
    }
    
    function testDeploymentOnFork() public {
        // Test deployment on forked network
        vm.prank(owner);
        TaskManager forkedTaskManager = new TaskManager();
        
        assertEq(forkedTaskManager.getTaskCount(), 0, "Initial task count should be 0");
        
        // Test basic functionality on fork
        vm.prank(user1);
        uint256 taskId = forkedTaskManager.createTask(
            "Integration Test Task",
            "Testing on forked network",
            block.timestamp + 1 days
        );
        
        assertEq(taskId, 1, "First task should have ID 1");
        assertEq(forkedTaskManager.getTaskCount(), 1, "Task count should be 1");
    }
    
    function testGasUsage() public {
        uint256 gasBefore = gasleft();
        
        vm.prank(user1);
        taskManager.createTask("Gas Test", "Testing gas usage", block.timestamp + 1 days);
        
        uint256 gasUsed = gasBefore - gasleft();
        console.log("Gas used for createTask:", gasUsed);
        
        // Assert reasonable gas usage (adjust based on your requirements)
        assertLt(gasUsed, 100000, "createTask should use less than 100k gas");
    }
}

## Deployment Testing Patterns

### Deployment Script
```solidity
// libs/blockchain/contracts/script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/TaskManager.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying TaskManager with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        TaskManager taskManager = new TaskManager();

        vm.stopBroadcast();

        console.log("TaskManager deployed at:", address(taskManager));

        // Verify deployment
        require(taskManager.getTaskCount() == 0, "Initial task count should be 0");
        console.log("Deployment verification passed");
    }
}
```

### Deployment Testing
```solidity
// libs/blockchain/contracts/test/Deploy.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../script/Deploy.s.sol";

contract DeployTest is Test {
    DeployScript deployScript;

    function setUp() public {
        deployScript = new DeployScript();
    }

    function testDeployment() public {
        // Set up environment variables for testing
        vm.setEnv("PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");

        // Fund the deployer
        address deployer = vm.addr(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        vm.deal(deployer, 10 ether);

        // Run deployment script
        deployScript.run();

        // The deployment script includes its own verification
        // Additional tests can be added here
    }

    function testDeploymentOnDifferentNetworks() public {
        string[] memory networks = new string[](3);
        networks[0] = "sepolia";
        networks[1] = "mumbai";
        networks[2] = "localhost";

        for (uint256 i = 0; i < networks.length; i++) {
            string memory network = networks[i];
            console.log("Testing deployment on:", network);

            // Create fork for each network
            if (keccak256(bytes(network)) == keccak256(bytes("sepolia"))) {
                vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
            } else if (keccak256(bytes(network)) == keccak256(bytes("mumbai"))) {
                vm.createFork(vm.envString("MUMBAI_RPC_URL"));
            }

            // Test deployment
            testDeployment();
        }
    }
}
```

## Coverage Requirements and Reporting

### Coverage Configuration
```bash
#!/bin/bash
# libs/blockchain/contracts/scripts/coverage.sh

set -e

echo "Running Foundry coverage analysis..."

# Run coverage with detailed reporting
forge coverage \
    --report lcov \
    --report summary \
    --report debug

# Generate HTML report
if command -v genhtml &> /dev/null; then
    echo "Generating HTML coverage report..."
    genhtml lcov.info -o coverage-report
    echo "HTML report generated in coverage-report/"
fi

# Check coverage thresholds
echo "Checking coverage thresholds..."

# Extract coverage percentage
COVERAGE=$(forge coverage --report summary | grep "Total" | awk '{print $4}' | sed 's/%//')

# Set minimum coverage threshold (80%)
MIN_COVERAGE=80

if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
    echo "❌ Coverage $COVERAGE% is below minimum threshold of $MIN_COVERAGE%"
    exit 1
else
    echo "✅ Coverage $COVERAGE% meets minimum threshold of $MIN_COVERAGE%"
fi
```

### GitHub Actions CI/CD Integration
```yaml
# .github/workflows/foundry-tests.yml
name: Foundry Smart Contract Tests

on:
  push:
    branches: [main]
    paths: ['libs/blockchain/contracts/**']
  pull_request:
    branches: [main]
    paths: ['libs/blockchain/contracts/**']

env:
  FOUNDRY_PROFILE: ci

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive

    - name: Install Foundry
      uses: foundry-rs/foundry-toolchain@v1
      with:
        version: nightly

    - name: Install dependencies
      run: |
        cd libs/blockchain/contracts
        forge install

    - name: Run tests
      run: |
        cd libs/blockchain/contracts
        forge test -vvv
      env:
        MAINNET_RPC_URL: ${{ secrets.MAINNET_RPC_URL }}
        SEPOLIA_RPC_URL: ${{ secrets.SEPOLIA_RPC_URL }}
        POLYGON_RPC_URL: ${{ secrets.POLYGON_RPC_URL }}
        MUMBAI_RPC_URL: ${{ secrets.MUMBAI_RPC_URL }}

    - name: Run coverage
      run: |
        cd libs/blockchain/contracts
        forge coverage --report lcov
      env:
        MAINNET_RPC_URL: ${{ secrets.MAINNET_RPC_URL }}
        SEPOLIA_RPC_URL: ${{ secrets.SEPOLIA_RPC_URL }}

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: libs/blockchain/contracts/lcov.info
        flags: foundry
        name: foundry-coverage

    - name: Run gas report
      run: |
        cd libs/blockchain/contracts
        forge test --gas-report > gas-report.txt

    - name: Comment gas report
      uses: actions/github-script@v6
      if: github.event_name == 'pull_request'
      with:
        script: |
          const fs = require('fs');
          const gasReport = fs.readFileSync('libs/blockchain/contracts/gas-report.txt', 'utf8');

          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## Gas Report\n\`\`\`\n${gasReport}\n\`\`\``
          });

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Install Foundry
      uses: foundry-rs/foundry-toolchain@v1

    - name: Run Slither
      uses: crytic/slither-action@v0.3.0
      with:
        target: libs/blockchain/contracts/src/
        slither-config: libs/blockchain/contracts/slither.config.json
        fail-on: high

    - name: Run Mythril
      run: |
        pip install mythril
        cd libs/blockchain/contracts
        myth analyze src/TaskManager.sol --solc-json mythril.json
```

## Best Practices

### Test Organization
- **Inheritance**: Use base test contracts for common setup and utilities
- **Naming**: Follow clear naming conventions (test*, testFuzz*, testFail*)
- **Isolation**: Each test should be independent and not rely on others
- **Coverage**: Aim for 80%+ code coverage with meaningful tests

### Fuzz Testing Guidelines
- **Input Bounds**: Always bound fuzz inputs to valid ranges
- **Assumptions**: Use vm.assume() to filter invalid inputs
- **Edge Cases**: Test boundary conditions and edge cases
- **Performance**: Balance fuzz runs with CI/CD performance

### Gas Optimization Testing
- **Gas Reports**: Generate gas reports for all public functions
- **Benchmarks**: Set gas usage benchmarks and monitor changes
- **Optimization**: Test gas optimizations with before/after comparisons
- **Regression**: Prevent gas usage regressions in CI/CD

### Security Testing
- **Static Analysis**: Use Slither and Mythril for static analysis
- **Access Control**: Test all access control mechanisms
- **Reentrancy**: Test for reentrancy vulnerabilities
- **Integer Overflow**: Test arithmetic operations for overflow/underflow

### Integration with NX
- **Affected Commands**: Use nx affected for efficient testing
- **Caching**: Leverage NX caching for faster builds
- **Dependencies**: Properly configure project dependencies
- **Parallel Execution**: Run tests in parallel where possible

This Foundry smart contract testing template provides comprehensive guidance for testing blockchain applications within our NX monorepo structure.
```
