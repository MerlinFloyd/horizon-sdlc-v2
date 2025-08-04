# Python AI Service Patterns Template

## Overview
This template provides comprehensive patterns for building Python AI services using LangChain, LangGraph, and Google Cloud AI SDK. It covers agent orchestration, model integration, data processing pipelines, and observability within our NX monorepo structure.

## Project Structure

### Standard Python AI Service Layout
```
apps/ai-agents/
├── src/
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── base_agent.py
│   │   ├── research_agent.py
│   │   └── orchestrator.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── client.py
│   │   └── schemas.py
│   ├── tools/
│   │   ├── __init__.py
│   │   ├── web_search.py
│   │   └── database.py
│   ├── memory/
│   │   ├── __init__.py
│   │   └── conversation.py
│   ├── pipelines/
│   │   ├── __init__.py
│   │   ├── rag.py
│   │   └── data_processing.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── routes/
│   │   └── middleware/
│   └── config/
│       ├── __init__.py
│       └── settings.py
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── k8s/
├── docs/
├── pyproject.toml
├── requirements.txt
├── Dockerfile
└── project.json
```

## Core Patterns

### 1. Google Cloud AI Client Configuration

#### Basic Client Setup
```python
from google import genai
from google.genai import types
import os
from typing import Optional

class AIModelClient:
    """Centralized client for Google Cloud AI services."""
    
    def __init__(self, project_id: str, location: str = "us-central1"):
        self.project_id = project_id
        self.location = location
        self._client: Optional[genai.Client] = None
    
    @property
    def client(self) -> genai.Client:
        """Lazy initialization of the AI client."""
        if self._client is None:
            self._client = genai.Client(
                vertexai=True,
                project=self.project_id,
                location=self.location
            )
        return self._client
    
    async def generate_content(
        self,
        model: str,
        contents: str,
        config: Optional[types.GenerateContentConfig] = None
    ) -> types.GenerateContentResponse:
        """Generate content with structured output support."""
        return await self.client.aio.models.generate_content(
            model=model,
            contents=contents,
            config=config or types.GenerateContentConfig()
        )
```

#### Environment Configuration
```python
# src/config/settings.py
from pydantic import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    """Application settings with environment variable support."""
    
    # Google Cloud Configuration
    google_cloud_project: str
    google_cloud_location: str = "us-central1"
    google_application_credentials: Optional[str] = None
    
    # Model Configuration
    default_model: str = "gemini-2.0-flash-001"
    max_tokens: int = 8192
    temperature: float = 0.7
    
    # OpenTelemetry Configuration
    otel_service_name: str = "ai-agents"
    otel_exporter_otlp_endpoint: Optional[str] = None
    
    # Database Configuration
    database_url: str
    redis_url: str
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
```

### 2. LangChain Agent Patterns

#### Base Agent Implementation
```python
from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.tools import BaseTool
from langchain_google_vertexai import ChatVertexAI
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)

class BaseAgent:
    """Base class for LangChain agents with standardized patterns."""
    
    def __init__(
        self,
        model_name: str,
        tools: List[BaseTool],
        system_prompt: str,
        project_id: str,
        location: str = "us-central1"
    ):
        self.model_name = model_name
        self.tools = tools
        self.system_prompt = system_prompt
        
        # Initialize LLM
        self.llm = ChatVertexAI(
            model_name=model_name,
            project=project_id,
            location=location,
            temperature=0.7,
            max_output_tokens=8192
        )
        
        # Create agent
        self.agent = self._create_agent()
        self.executor = AgentExecutor(
            agent=self.agent,
            tools=self.tools,
            verbose=True,
            handle_parsing_errors=True
        )
    
    def _create_agent(self):
        """Create the agent with prompt template."""
        prompt = ChatPromptTemplate.from_messages([
            ("system", self.system_prompt),
            ("user", "{input}"),
            ("placeholder", "{agent_scratchpad}"),
        ])
        
        return create_tool_calling_agent(
            self.llm,
            self.tools,
            prompt
        )
    
    async def invoke(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the agent with input data."""
        try:
            result = await self.executor.ainvoke(input_data)
            logger.info(f"Agent execution completed: {result}")
            return result
        except Exception as e:
            logger.error(f"Agent execution failed: {e}")
            raise
```

### 4. FastAPI Integration

#### Main Application Setup
```python
# src/api/main.py
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

from ..config.settings import settings
from ..models.client import AIModelClient
from .routes import agents, health

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure OpenTelemetry
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

if settings.otel_exporter_otlp_endpoint:
    otlp_exporter = OTLPSpanExporter(
        endpoint=settings.otel_exporter_otlp_endpoint,
        insecure=True
    )
    span_processor = BatchSpanProcessor(otlp_exporter)
    trace.get_tracer_provider().add_span_processor(span_processor)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management."""
    logger.info("Starting AI service...")
    
    # Initialize AI client
    app.state.ai_client = AIModelClient(
        project_id=settings.google_cloud_project,
        location=settings.google_cloud_location
    )
    
    yield
    
    logger.info("Shutting down AI service...")

# Create FastAPI application
app = FastAPI(
    title="AI Agents Service",
    description="LangChain-based AI agent orchestration service",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Instrument FastAPI with OpenTelemetry
FastAPIInstrumentor.instrument_app(app)

# Include routers
app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(agents.router, prefix="/api/v1/agents", tags=["agents"])

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "AI Agents Service", "version": "1.0.0"}
```

### 5. Testing Patterns

#### Unit Test Example
```python
# tests/unit/test_agents.py
import pytest
from unittest.mock import AsyncMock, MagicMock
from src.agents.base_agent import BaseAgent
from langchain_core.tools import BaseTool

class MockTool(BaseTool):
    name = "mock_tool"
    description = "A mock tool for testing"
    
    def _run(self, query: str) -> str:
        return f"Mock result for: {query}"

@pytest.fixture
def mock_agent():
    """Create a mock agent for testing."""
    tools = [MockTool()]
    return BaseAgent(
        model_name="gemini-pro",
        tools=tools,
        system_prompt="You are a test agent.",
        project_id="test-project"
    )

@pytest.mark.asyncio
async def test_agent_invoke(mock_agent):
    """Test agent invocation."""
    # Mock the executor
    mock_agent.executor.ainvoke = AsyncMock(
        return_value={"output": "Test response"}
    )
    
    result = await mock_agent.invoke({"input": "Test query"})
    
    assert result["output"] == "Test response"
    mock_agent.executor.ainvoke.assert_called_once()
```

### 6. OpenTelemetry Instrumentation

#### Custom Instrumentation
```python
# src/observability/tracing.py
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode
from functools import wraps
import logging

logger = logging.getLogger(__name__)
tracer = trace.get_tracer(__name__)

def trace_agent_execution(operation_name: str):
    """Decorator for tracing agent operations."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(operation_name) as span:
                try:
                    # Add attributes
                    span.set_attribute("agent.operation", operation_name)
                    if args:
                        span.set_attribute("agent.input_type", type(args[0]).__name__)
                    
                    result = await func(*args, **kwargs)
                    
                    # Mark as successful
                    span.set_status(Status(StatusCode.OK))
                    return result
                    
                except Exception as e:
                    # Record error
                    span.record_exception(e)
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    logger.error(f"Agent operation {operation_name} failed: {e}")
                    raise
        
        return wrapper
    return decorator
```
