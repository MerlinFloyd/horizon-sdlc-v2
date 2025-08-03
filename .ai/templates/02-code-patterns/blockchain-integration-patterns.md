# Blockchain Integration Patterns Template

## Overview
This template provides comprehensive patterns for blockchain integration supporting multi-network environments (Ethereum, Polygon, Solana), smart contract interaction, event listening, transaction handling, and deployment patterns within our NX monorepo structure.

## Multi-Network Support Patterns

### Network Configuration
```typescript
// libs/shared/blockchain/src/config/networks.ts
export interface NetworkConfig {
  chainId: number;
  name: string;
  rpcUrl: string;
  explorerUrl: string;
  nativeCurrency: {
    name: string;
    symbol: string;
    decimals: number;
  };
  contracts?: Record<string, string>;
}

export const SUPPORTED_NETWORKS: Record<string, NetworkConfig> = {
  ethereum: {
    chainId: 1,
    name: 'Ethereum Mainnet',
    rpcUrl: process.env.ETHEREUM_RPC_URL || 'https://mainnet.infura.io/v3/YOUR_KEY',
    explorerUrl: 'https://etherscan.io',
    nativeCurrency: {
      name: 'Ether',
      symbol: 'ETH',
      decimals: 18
    },
    contracts: {
      taskManager: process.env.ETHEREUM_TASK_MANAGER_CONTRACT
    }
  },
  polygon: {
    chainId: 137,
    name: 'Polygon Mainnet',
    rpcUrl: process.env.POLYGON_RPC_URL || 'https://polygon-rpc.com',
    explorerUrl: 'https://polygonscan.com',
    nativeCurrency: {
      name: 'MATIC',
      symbol: 'MATIC',
      decimals: 18
    },
    contracts: {
      taskManager: process.env.POLYGON_TASK_MANAGER_CONTRACT
    }
  },
  solana: {
    chainId: 101, // Solana mainnet
    name: 'Solana Mainnet',
    rpcUrl: process.env.SOLANA_RPC_URL || 'https://api.mainnet-beta.solana.com',
    explorerUrl: 'https://explorer.solana.com',
    nativeCurrency: {
      name: 'SOL',
      symbol: 'SOL',
      decimals: 9
    },
    contracts: {
      taskManager: process.env.SOLANA_TASK_MANAGER_PROGRAM
    }
  }
};

export const TESTNET_NETWORKS: Record<string, NetworkConfig> = {
  sepolia: {
    chainId: 11155111,
    name: 'Sepolia Testnet',
    rpcUrl: process.env.SEPOLIA_RPC_URL || 'https://sepolia.infura.io/v3/YOUR_KEY',
    explorerUrl: 'https://sepolia.etherscan.io',
    nativeCurrency: {
      name: 'Sepolia Ether',
      symbol: 'SEP',
      decimals: 18
    },
    contracts: {
      taskManager: process.env.SEPOLIA_TASK_MANAGER_CONTRACT
    }
  },
  mumbai: {
    chainId: 80001,
    name: 'Mumbai Testnet',
    rpcUrl: process.env.MUMBAI_RPC_URL || 'https://rpc-mumbai.maticvigil.com',
    explorerUrl: 'https://mumbai.polygonscan.com',
    nativeCurrency: {
      name: 'MATIC',
      symbol: 'MATIC',
      decimals: 18
    },
    contracts: {
      taskManager: process.env.MUMBAI_TASK_MANAGER_CONTRACT
    }
  },
  devnet: {
    chainId: 103, // Solana devnet
    name: 'Solana Devnet',
    rpcUrl: process.env.SOLANA_DEVNET_RPC_URL || 'https://api.devnet.solana.com',
    explorerUrl: 'https://explorer.solana.com/?cluster=devnet',
    nativeCurrency: {
      name: 'SOL',
      symbol: 'SOL',
      decimals: 9
    },
    contracts: {
      taskManager: process.env.SOLANA_DEVNET_TASK_MANAGER_PROGRAM
    }
  }
};
```

### Network Provider Factory
```typescript
// libs/shared/blockchain/src/providers/network-provider.factory.ts
import { ethers } from 'ethers';
import { Connection, PublicKey } from '@solana/web3.js';
import { NetworkConfig } from '../config/networks';

export interface BlockchainProvider {
  getBalance(address: string): Promise<string>;
  getBlockNumber(): Promise<number>;
  estimateGas?(transaction: any): Promise<string>;
  sendTransaction(transaction: any): Promise<string>;
}

export class EthereumProvider implements BlockchainProvider {
  private provider: ethers.JsonRpcProvider;

  constructor(private config: NetworkConfig) {
    this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
  }

  async getBalance(address: string): Promise<string> {
    const balance = await this.provider.getBalance(address);
    return ethers.formatEther(balance);
  }

  async getBlockNumber(): Promise<number> {
    return await this.provider.getBlockNumber();
  }

  async estimateGas(transaction: any): Promise<string> {
    const gasEstimate = await this.provider.estimateGas(transaction);
    return gasEstimate.toString();
  }

  async sendTransaction(transaction: any): Promise<string> {
    const tx = await this.provider.sendTransaction(transaction);
    return tx.hash;
  }

  getProvider(): ethers.JsonRpcProvider {
    return this.provider;
  }
}

export class SolanaProvider implements BlockchainProvider {
  private connection: Connection;

  constructor(private config: NetworkConfig) {
    this.connection = new Connection(config.rpcUrl, 'confirmed');
  }

  async getBalance(address: string): Promise<string> {
    const publicKey = new PublicKey(address);
    const balance = await this.connection.getBalance(publicKey);
    return (balance / 1e9).toString(); // Convert lamports to SOL
  }

  async getBlockNumber(): Promise<number> {
    return await this.connection.getSlot();
  }

  async sendTransaction(transaction: any): Promise<string> {
    const signature = await this.connection.sendRawTransaction(transaction);
    return signature;
  }

  getConnection(): Connection {
    return this.connection;
  }
}

export class NetworkProviderFactory {
  static createProvider(config: NetworkConfig): BlockchainProvider {
    if (config.name.toLowerCase().includes('solana')) {
      return new SolanaProvider(config);
    } else {
      return new EthereumProvider(config);
    }
  }
}
```

## Smart Contract Interaction Patterns

### Contract Interface Definitions
```typescript
// libs/shared/blockchain/src/contracts/task-manager.interface.ts
export interface TaskManagerContract {
  // Read methods
  getTask(taskId: string): Promise<Task>;
  getTasks(owner: string): Promise<Task[]>;
  getTaskCount(): Promise<number>;
  
  // Write methods
  createTask(title: string, description: string, dueDate: number): Promise<string>;
  updateTask(taskId: string, title: string, description: string): Promise<string>;
  completeTask(taskId: string): Promise<string>;
  deleteTask(taskId: string): Promise<string>;
  
  // Events
  onTaskCreated(callback: (event: TaskCreatedEvent) => void): void;
  onTaskUpdated(callback: (event: TaskUpdatedEvent) => void): void;
  onTaskCompleted(callback: (event: TaskCompletedEvent) => void): void;
}

export interface Task {
  id: string;
  owner: string;
  title: string;
  description: string;
  completed: boolean;
  createdAt: number;
  dueDate: number;
}

export interface TaskCreatedEvent {
  taskId: string;
  owner: string;
  title: string;
  blockNumber: number;
  transactionHash: string;
}

export interface TaskUpdatedEvent {
  taskId: string;
  title: string;
  description: string;
  blockNumber: number;
  transactionHash: string;
}

export interface TaskCompletedEvent {
  taskId: string;
  completedAt: number;
  blockNumber: number;
  transactionHash: string;
}
```

### Ethereum Contract Implementation
```typescript
// libs/shared/blockchain/src/contracts/ethereum/task-manager.contract.ts
import { ethers } from 'ethers';
import { TaskManagerContract, Task, TaskCreatedEvent } from '../task-manager.interface';

const TASK_MANAGER_ABI = [
  "function createTask(string memory title, string memory description, uint256 dueDate) external returns (uint256)",
  "function getTask(uint256 taskId) external view returns (tuple(uint256 id, address owner, string title, string description, bool completed, uint256 createdAt, uint256 dueDate))",
  "function getTasks(address owner) external view returns (tuple(uint256 id, address owner, string title, string description, bool completed, uint256 createdAt, uint256 dueDate)[])",
  "function updateTask(uint256 taskId, string memory title, string memory description) external",
  "function completeTask(uint256 taskId) external",
  "function deleteTask(uint256 taskId) external",
  "event TaskCreated(uint256 indexed taskId, address indexed owner, string title)",
  "event TaskUpdated(uint256 indexed taskId, string title, string description)",
  "event TaskCompleted(uint256 indexed taskId, uint256 completedAt)"
];

export class EthereumTaskManagerContract implements TaskManagerContract {
  private contract: ethers.Contract;
  private signer: ethers.Signer;

  constructor(
    contractAddress: string,
    provider: ethers.JsonRpcProvider,
    signer?: ethers.Signer
  ) {
    this.contract = new ethers.Contract(contractAddress, TASK_MANAGER_ABI, provider);
    this.signer = signer || provider;
    
    if (signer) {
      this.contract = this.contract.connect(signer);
    }
  }

  async getTask(taskId: string): Promise<Task> {
    const task = await this.contract.getTask(taskId);
    return {
      id: task.id.toString(),
      owner: task.owner,
      title: task.title,
      description: task.description,
      completed: task.completed,
      createdAt: Number(task.createdAt),
      dueDate: Number(task.dueDate)
    };
  }

  async getTasks(owner: string): Promise<Task[]> {
    const tasks = await this.contract.getTasks(owner);
    return tasks.map((task: any) => ({
      id: task.id.toString(),
      owner: task.owner,
      title: task.title,
      description: task.description,
      completed: task.completed,
      createdAt: Number(task.createdAt),
      dueDate: Number(task.dueDate)
    }));
  }

  async getTaskCount(): Promise<number> {
    const count = await this.contract.taskCount();
    return Number(count);
  }

  async createTask(title: string, description: string, dueDate: number): Promise<string> {
    const tx = await this.contract.createTask(title, description, dueDate);
    const receipt = await tx.wait();
    return receipt.hash;
  }

  async updateTask(taskId: string, title: string, description: string): Promise<string> {
    const tx = await this.contract.updateTask(taskId, title, description);
    const receipt = await tx.wait();
    return receipt.hash;
  }

  async completeTask(taskId: string): Promise<string> {
    const tx = await this.contract.completeTask(taskId);
    const receipt = await tx.wait();
    return receipt.hash;
  }

  async deleteTask(taskId: string): Promise<string> {
    const tx = await this.contract.deleteTask(taskId);
    const receipt = await tx.wait();
    return receipt.hash;
  }

  onTaskCreated(callback: (event: TaskCreatedEvent) => void): void {
    this.contract.on('TaskCreated', (taskId, owner, title, event) => {
      callback({
        taskId: taskId.toString(),
        owner,
        title,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      });
    });
  }

  onTaskUpdated(callback: (event: any) => void): void {
    this.contract.on('TaskUpdated', callback);
  }

  onTaskCompleted(callback: (event: any) => void): void {
    this.contract.on('TaskCompleted', callback);
  }

  // Gas estimation helper
  async estimateGas(method: string, ...args: any[]): Promise<bigint> {
    return await this.contract[method].estimateGas(...args);
  }

  // Get current gas price
  async getGasPrice(): Promise<bigint> {
    return await this.contract.provider.getFeeData().then(fee => fee.gasPrice || 0n);
  }
}

### Solana Program Implementation
```typescript
// libs/shared/blockchain/src/contracts/solana/task-manager.program.ts
import {
  Connection,
  PublicKey,
  Transaction,
  TransactionInstruction,
  SystemProgram,
  SYSVAR_RENT_PUBKEY
} from '@solana/web3.js';
import { Program, AnchorProvider, web3, BN } from '@coral-xyz/anchor';
import { TaskManagerContract, Task } from '../task-manager.interface';

export class SolanaTaskManagerProgram implements TaskManagerContract {
  private connection: Connection;
  private program: Program;
  private programId: PublicKey;

  constructor(
    programId: string,
    connection: Connection,
    provider: AnchorProvider
  ) {
    this.connection = connection;
    this.programId = new PublicKey(programId);
    // Initialize program with IDL
    this.program = new Program(TASK_MANAGER_IDL, this.programId, provider);
  }

  async getTask(taskId: string): Promise<Task> {
    const taskPubkey = new PublicKey(taskId);
    const taskAccount = await this.program.account.task.fetch(taskPubkey);

    return {
      id: taskPubkey.toString(),
      owner: taskAccount.owner.toString(),
      title: taskAccount.title,
      description: taskAccount.description,
      completed: taskAccount.completed,
      createdAt: taskAccount.createdAt.toNumber(),
      dueDate: taskAccount.dueDate.toNumber()
    };
  }

  async getTasks(owner: string): Promise<Task[]> {
    const ownerPubkey = new PublicKey(owner);
    const tasks = await this.program.account.task.all([
      {
        memcmp: {
          offset: 8, // Discriminator offset
          bytes: ownerPubkey.toBase58()
        }
      }
    ]);

    return tasks.map(task => ({
      id: task.publicKey.toString(),
      owner: task.account.owner.toString(),
      title: task.account.title,
      description: task.account.description,
      completed: task.account.completed,
      createdAt: task.account.createdAt.toNumber(),
      dueDate: task.account.dueDate.toNumber()
    }));
  }

  async getTaskCount(): Promise<number> {
    const tasks = await this.program.account.task.all();
    return tasks.length;
  }

  async createTask(title: string, description: string, dueDate: number): Promise<string> {
    const taskKeypair = web3.Keypair.generate();

    const tx = await this.program.methods
      .createTask(title, description, new BN(dueDate))
      .accounts({
        task: taskKeypair.publicKey,
        user: this.program.provider.publicKey,
        systemProgram: SystemProgram.programId,
        rent: SYSVAR_RENT_PUBKEY
      })
      .signers([taskKeypair])
      .rpc();

    return tx;
  }

  async updateTask(taskId: string, title: string, description: string): Promise<string> {
    const taskPubkey = new PublicKey(taskId);

    const tx = await this.program.methods
      .updateTask(title, description)
      .accounts({
        task: taskPubkey,
        user: this.program.provider.publicKey
      })
      .rpc();

    return tx;
  }

  async completeTask(taskId: string): Promise<string> {
    const taskPubkey = new PublicKey(taskId);

    const tx = await this.program.methods
      .completeTask()
      .accounts({
        task: taskPubkey,
        user: this.program.provider.publicKey
      })
      .rpc();

    return tx;
  }

  async deleteTask(taskId: string): Promise<string> {
    const taskPubkey = new PublicKey(taskId);

    const tx = await this.program.methods
      .deleteTask()
      .accounts({
        task: taskPubkey,
        user: this.program.provider.publicKey
      })
      .rpc();

    return tx;
  }

  onTaskCreated(callback: (event: any) => void): void {
    this.program.addEventListener('TaskCreated', callback);
  }

  onTaskUpdated(callback: (event: any) => void): void {
    this.program.addEventListener('TaskUpdated', callback);
  }

  onTaskCompleted(callback: (event: any) => void): void {
    this.program.addEventListener('TaskCompleted', callback);
  }
}

// Solana Program IDL (Interface Definition Language)
const TASK_MANAGER_IDL = {
  version: "0.1.0",
  name: "task_manager",
  instructions: [
    {
      name: "createTask",
      accounts: [
        { name: "task", isMut: true, isSigner: true },
        { name: "user", isMut: true, isSigner: true },
        { name: "systemProgram", isMut: false, isSigner: false },
        { name: "rent", isMut: false, isSigner: false }
      ],
      args: [
        { name: "title", type: "string" },
        { name: "description", type: "string" },
        { name: "dueDate", type: "i64" }
      ]
    },
    {
      name: "updateTask",
      accounts: [
        { name: "task", isMut: true, isSigner: false },
        { name: "user", isMut: false, isSigner: true }
      ],
      args: [
        { name: "title", type: "string" },
        { name: "description", type: "string" }
      ]
    },
    {
      name: "completeTask",
      accounts: [
        { name: "task", isMut: true, isSigner: false },
        { name: "user", isMut: false, isSigner: true }
      ],
      args: []
    },
    {
      name: "deleteTask",
      accounts: [
        { name: "task", isMut: true, isSigner: false },
        { name: "user", isMut: false, isSigner: true }
      ],
      args: []
    }
  ],
  accounts: [
    {
      name: "Task",
      type: {
        kind: "struct",
        fields: [
          { name: "owner", type: "publicKey" },
          { name: "title", type: "string" },
          { name: "description", type: "string" },
          { name: "completed", type: "bool" },
          { name: "createdAt", type: "i64" },
          { name: "dueDate", type: "i64" }
        ]
      }
    }
  ],
  events: [
    {
      name: "TaskCreated",
      fields: [
        { name: "taskId", type: "publicKey", index: true },
        { name: "owner", type: "publicKey", index: true },
        { name: "title", type: "string", index: false }
      ]
    }
  ]
};
```

## Transaction Handling Patterns

### Transaction Manager
```typescript
// libs/shared/blockchain/src/transactions/transaction-manager.ts
import { EventEmitter } from 'events';

export interface TransactionRequest {
  id: string;
  network: string;
  method: string;
  params: any[];
  gasLimit?: string;
  gasPrice?: string;
  value?: string;
}

export interface TransactionResult {
  id: string;
  hash: string;
  status: 'pending' | 'confirmed' | 'failed';
  blockNumber?: number;
  gasUsed?: string;
  error?: string;
}

export class TransactionManager extends EventEmitter {
  private pendingTransactions = new Map<string, TransactionRequest>();
  private transactionResults = new Map<string, TransactionResult>();

  async submitTransaction(request: TransactionRequest): Promise<string> {
    this.pendingTransactions.set(request.id, request);

    try {
      // Get the appropriate provider for the network
      const provider = this.getProviderForNetwork(request.network);

      // Execute the transaction
      const hash = await this.executeTransaction(provider, request);

      const result: TransactionResult = {
        id: request.id,
        hash,
        status: 'pending'
      };

      this.transactionResults.set(request.id, result);
      this.emit('transactionSubmitted', result);

      // Start monitoring the transaction
      this.monitorTransaction(request.network, hash, request.id);

      return hash;
    } catch (error) {
      const result: TransactionResult = {
        id: request.id,
        hash: '',
        status: 'failed',
        error: error instanceof Error ? error.message : 'Unknown error'
      };

      this.transactionResults.set(request.id, result);
      this.emit('transactionFailed', result);

      throw error;
    }
  }

  async getTransactionStatus(id: string): Promise<TransactionResult | null> {
    return this.transactionResults.get(id) || null;
  }

  private async executeTransaction(provider: any, request: TransactionRequest): Promise<string> {
    // Implementation depends on the network type
    if (request.network.includes('solana')) {
      return this.executeSolanaTransaction(provider, request);
    } else {
      return this.executeEthereumTransaction(provider, request);
    }
  }

  private async executeEthereumTransaction(provider: any, request: TransactionRequest): Promise<string> {
    const tx = {
      to: request.params[0],
      data: request.params[1],
      gasLimit: request.gasLimit,
      gasPrice: request.gasPrice,
      value: request.value || '0'
    };

    const response = await provider.sendTransaction(tx);
    return response.hash;
  }

  private async executeSolanaTransaction(provider: any, request: TransactionRequest): Promise<string> {
    // Solana transaction execution logic
    const transaction = request.params[0]; // Pre-built transaction
    const signature = await provider.sendRawTransaction(transaction);
    return signature;
  }

  private async monitorTransaction(network: string, hash: string, id: string): Promise<void> {
    const provider = this.getProviderForNetwork(network);
    const maxAttempts = 60; // 5 minutes with 5-second intervals
    let attempts = 0;

    const checkStatus = async () => {
      try {
        const receipt = await provider.getTransactionReceipt(hash);

        if (receipt) {
          const result: TransactionResult = {
            id,
            hash,
            status: receipt.status === 1 ? 'confirmed' : 'failed',
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed?.toString()
          };

          this.transactionResults.set(id, result);
          this.emit('transactionConfirmed', result);
          this.pendingTransactions.delete(id);
        } else if (attempts < maxAttempts) {
          attempts++;
          setTimeout(checkStatus, 5000); // Check again in 5 seconds
        } else {
          // Transaction timeout
          const result: TransactionResult = {
            id,
            hash,
            status: 'failed',
            error: 'Transaction timeout'
          };

          this.transactionResults.set(id, result);
          this.emit('transactionFailed', result);
          this.pendingTransactions.delete(id);
        }
      } catch (error) {
        if (attempts < maxAttempts) {
          attempts++;
          setTimeout(checkStatus, 5000);
        } else {
          const result: TransactionResult = {
            id,
            hash,
            status: 'failed',
            error: error instanceof Error ? error.message : 'Unknown error'
          };

          this.transactionResults.set(id, result);
          this.emit('transactionFailed', result);
          this.pendingTransactions.delete(id);
        }
      }
    };

    checkStatus();
  }

  private getProviderForNetwork(network: string): any {
    // Return the appropriate provider based on network
    // This would be injected or configured based on your setup
    throw new Error('Provider not configured for network: ' + network);
  }
}

## Event Listening Patterns

### Blockchain Event Listener
```typescript
// libs/shared/blockchain/src/events/event-listener.ts
import { EventEmitter } from 'events';
import { ethers } from 'ethers';

export interface BlockchainEvent {
  id: string;
  network: string;
  contractAddress: string;
  eventName: string;
  blockNumber: number;
  transactionHash: string;
  args: any[];
  timestamp: number;
}

export class BlockchainEventListener extends EventEmitter {
  private listeners = new Map<string, any>();
  private isListening = false;

  constructor(
    private network: string,
    private provider: ethers.JsonRpcProvider
  ) {
    super();
  }

  async startListening(): Promise<void> {
    if (this.isListening) {
      return;
    }

    this.isListening = true;
    console.log(`Started listening for events on ${this.network}`);

    // Listen for new blocks
    this.provider.on('block', (blockNumber) => {
      this.emit('newBlock', { network: this.network, blockNumber });
    });
  }

  async stopListening(): Promise<void> {
    if (!this.isListening) {
      return;
    }

    this.isListening = false;
    this.provider.removeAllListeners();
    this.listeners.clear();

    console.log(`Stopped listening for events on ${this.network}`);
  }

  addContractEventListener(
    contractAddress: string,
    abi: any[],
    eventName: string,
    callback: (event: BlockchainEvent) => void
  ): string {
    const contract = new ethers.Contract(contractAddress, abi, this.provider);
    const listenerId = `${contractAddress}-${eventName}-${Date.now()}`;

    const eventListener = (...args: any[]) => {
      const event = args[args.length - 1]; // Last argument is the event object

      const blockchainEvent: BlockchainEvent = {
        id: `${event.transactionHash}-${event.logIndex}`,
        network: this.network,
        contractAddress,
        eventName,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash,
        args: args.slice(0, -1), // Remove the event object
        timestamp: Date.now()
      };

      callback(blockchainEvent);
      this.emit('contractEvent', blockchainEvent);
    };

    contract.on(eventName, eventListener);
    this.listeners.set(listenerId, { contract, eventName, listener: eventListener });

    return listenerId;
  }

  removeEventListener(listenerId: string): void {
    const listener = this.listeners.get(listenerId);
    if (listener) {
      listener.contract.off(listener.eventName, listener.listener);
      this.listeners.delete(listenerId);
    }
  }

  async getHistoricalEvents(
    contractAddress: string,
    abi: any[],
    eventName: string,
    fromBlock: number,
    toBlock: number = 'latest'
  ): Promise<BlockchainEvent[]> {
    const contract = new ethers.Contract(contractAddress, abi, this.provider);
    const filter = contract.filters[eventName]();

    const events = await contract.queryFilter(filter, fromBlock, toBlock);

    return events.map(event => ({
      id: `${event.transactionHash}-${event.index}`,
      network: this.network,
      contractAddress,
      eventName,
      blockNumber: event.blockNumber,
      transactionHash: event.transactionHash,
      args: event.args ? Array.from(event.args) : [],
      timestamp: Date.now() // Note: This is current time, not block time
    }));
  }
}
```

### Event Processing Service
```typescript
// libs/shared/blockchain/src/events/event-processor.ts
import { Injectable } from '@nestjs/common';
import { BlockchainEvent } from './event-listener';
import { EventPublisher } from '@shared/messaging';

@Injectable()
export class BlockchainEventProcessor {
  constructor(private eventPublisher: EventPublisher) {}

  async processEvent(event: BlockchainEvent): Promise<void> {
    try {
      switch (event.eventName) {
        case 'TaskCreated':
          await this.processTaskCreatedEvent(event);
          break;
        case 'TaskUpdated':
          await this.processTaskUpdatedEvent(event);
          break;
        case 'TaskCompleted':
          await this.processTaskCompletedEvent(event);
          break;
        default:
          console.log(`Unhandled event: ${event.eventName}`);
      }
    } catch (error) {
      console.error('Error processing blockchain event:', error);
      // Send to dead letter queue or retry mechanism
      await this.handleEventProcessingError(event, error);
    }
  }

  private async processTaskCreatedEvent(event: BlockchainEvent): Promise<void> {
    const [taskId, owner, title] = event.args;

    // Publish domain event
    await this.eventPublisher.publishDomainEvent(
      'task-created-on-blockchain',
      'tasks',
      {
        taskId: taskId.toString(),
        owner,
        title,
        network: event.network,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      }
    );

    console.log(`Task created on blockchain: ${taskId} by ${owner}`);
  }

  private async processTaskUpdatedEvent(event: BlockchainEvent): Promise<void> {
    const [taskId, title, description] = event.args;

    await this.eventPublisher.publishDomainEvent(
      'task-updated-on-blockchain',
      'tasks',
      {
        taskId: taskId.toString(),
        title,
        description,
        network: event.network,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      }
    );

    console.log(`Task updated on blockchain: ${taskId}`);
  }

  private async processTaskCompletedEvent(event: BlockchainEvent): Promise<void> {
    const [taskId, completedAt] = event.args;

    await this.eventPublisher.publishDomainEvent(
      'task-completed-on-blockchain',
      'tasks',
      {
        taskId: taskId.toString(),
        completedAt: Number(completedAt),
        network: event.network,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      }
    );

    console.log(`Task completed on blockchain: ${taskId}`);
  }

  private async handleEventProcessingError(event: BlockchainEvent, error: any): Promise<void> {
    // Log error details
    console.error('Event processing failed:', {
      eventId: event.id,
      eventName: event.eventName,
      network: event.network,
      error: error.message
    });

    // Send to error handling system
    await this.eventPublisher.publishDomainEvent(
      'blockchain-event-processing-failed',
      'system',
      {
        event,
        error: error.message,
        timestamp: new Date().toISOString()
      }
    );
  }
}
```

## Best Practices

### Gas Optimization
- **Batch Transactions**: Group multiple operations into single transactions
- **Gas Estimation**: Always estimate gas before sending transactions
- **Gas Price Monitoring**: Monitor and adjust gas prices based on network conditions
- **Contract Optimization**: Optimize smart contract code for gas efficiency

### Error Handling
- **Network Failures**: Implement retry mechanisms for network failures
- **Transaction Failures**: Handle failed transactions gracefully
- **Event Processing**: Implement robust event processing with error recovery
- **Fallback Mechanisms**: Provide fallback options when blockchain is unavailable

### Security Considerations
- **Private Key Management**: Never expose private keys in client-side code
- **Input Validation**: Validate all inputs before sending to blockchain
- **Reentrancy Protection**: Implement reentrancy guards in smart contracts
- **Access Control**: Implement proper access control in smart contracts

### Performance Optimization
- **Connection Pooling**: Use connection pooling for blockchain providers
- **Caching**: Cache frequently accessed blockchain data
- **Event Filtering**: Use efficient event filtering to reduce processing load
- **Batch Processing**: Process events in batches for better performance

### Monitoring and Observability
- **Transaction Monitoring**: Monitor transaction status and completion
- **Event Tracking**: Track and log all blockchain events
- **Performance Metrics**: Monitor gas usage and transaction times
- **Error Tracking**: Track and analyze blockchain-related errors

This blockchain integration patterns template provides comprehensive guidance for building robust, multi-network blockchain applications within our NX monorepo structure.

