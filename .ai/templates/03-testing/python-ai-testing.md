# Python AI Testing Template

## Overview
This template provides comprehensive testing patterns for Python AI services using pytest, including unit tests for LangChain agents, integration tests for AI pipelines, and E2E tests with Playwright. Follows our 80% coverage requirement and excludes integration testing per our standards.

## Testing Structure

### Standard Test Organization
```
tests/
├── unit/
│   ├── __init__.py
│   ├── test_agents/
│   │   ├── __init__.py
│   │   ├── test_base_agent.py
│   │   └── test_research_agent.py
│   ├── test_models/
│   │   ├── __init__.py
│   │   ├── test_client.py
│   │   └── test_schemas.py
│   ├── test_tools/
│   │   ├── __init__.py
│   │   ├── test_web_search.py
│   │   └── test_database.py
│   └── test_pipelines/
│       ├── __init__.py
│       ├── test_rag.py
│       └── test_data_processing.py
├── e2e/
│   ├── __init__.py
│   ├── test_agent_workflows.py
│   └── test_api_endpoints.py
├── fixtures/
│   ├── __init__.py
│   ├── agent_fixtures.py
│   ├── model_fixtures.py
│   └── data_fixtures.py
└── conftest.py
```

## Unit Testing Patterns

### 1. Agent Testing
```python
# tests/unit/test_agents/test_base_agent.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from langchain_core.tools import BaseTool
from langchain_core.messages import AIMessage

from src.agents.base_agent import BaseAgent
from src.config.settings import settings

class MockTool(BaseTool):
    """Mock tool for testing."""
    name = "mock_tool"
    description = "A mock tool for testing"
    
    def _run(self, query: str) -> str:
        return f"Mock result for: {query}"
    
    async def _arun(self, query: str) -> str:
        return f"Mock async result for: {query}"

@pytest.fixture
def mock_tools():
    """Create mock tools for testing."""
    return [MockTool()]

@pytest.fixture
def base_agent(mock_tools):
    """Create a base agent for testing."""
    with patch('src.agents.base_agent.ChatVertexAI') as mock_llm:
        mock_llm.return_value = MagicMock()
        agent = BaseAgent(
            model_name="gemini-pro",
            tools=mock_tools,
            system_prompt="You are a test agent.",
            project_id="test-project"
        )
        return agent

@pytest.mark.asyncio
async def test_agent_invoke_success(base_agent):
    """Test successful agent invocation."""
    # Mock the executor
    expected_result = {"output": "Test response", "input": "Test query"}
    base_agent.executor.ainvoke = AsyncMock(return_value=expected_result)
    
    result = await base_agent.invoke({"input": "Test query"})
    
    assert result == expected_result
    base_agent.executor.ainvoke.assert_called_once_with({"input": "Test query"})

@pytest.mark.asyncio
async def test_agent_invoke_error(base_agent):
    """Test agent invocation with error."""
    # Mock the executor to raise an exception
    base_agent.executor.ainvoke = AsyncMock(side_effect=Exception("Test error"))
    
    with pytest.raises(Exception, match="Test error"):
        await base_agent.invoke({"input": "Test query"})

@pytest.mark.asyncio
async def test_agent_with_custom_prompt(mock_tools):
    """Test agent creation with custom prompt."""
    custom_prompt = "You are a specialized test agent."
    
    with patch('src.agents.base_agent.ChatVertexAI') as mock_llm:
        mock_llm.return_value = MagicMock()
        agent = BaseAgent(
            model_name="gemini-pro",
            tools=mock_tools,
            system_prompt=custom_prompt,
            project_id="test-project"
        )
        
        assert agent.system_prompt == custom_prompt
```

### 2. Model Client Testing
```python
# tests/unit/test_models/test_client.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from google.genai import types

from src.models.client import AIModelClient

@pytest.fixture
def ai_client():
    """Create AI client for testing."""
    return AIModelClient(project_id="test-project", location="us-central1")

@pytest.mark.asyncio
async def test_client_initialization(ai_client):
    """Test client initialization."""
    assert ai_client.project_id == "test-project"
    assert ai_client.location == "us-central1"
    assert ai_client._client is None

@pytest.mark.asyncio
async def test_client_lazy_initialization(ai_client):
    """Test lazy client initialization."""
    with patch('src.models.client.genai.Client') as mock_client_class:
        mock_client = MagicMock()
        mock_client_class.return_value = mock_client
        
        client = ai_client.client
        
        assert client == mock_client
        mock_client_class.assert_called_once_with(
            vertexai=True,
            project="test-project",
            location="us-central1"
        )

@pytest.mark.asyncio
async def test_generate_content_success(ai_client):
    """Test successful content generation."""
    mock_response = MagicMock()
    mock_response.text = "Generated content"
    
    with patch.object(ai_client, 'client') as mock_client:
        mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)
        
        result = await ai_client.generate_content(
            model="gemini-pro",
            contents="Test prompt"
        )
        
        assert result == mock_response
        mock_client.aio.models.generate_content.assert_called_once()

@pytest.mark.asyncio
async def test_generate_content_with_config(ai_client):
    """Test content generation with custom config."""
    mock_response = MagicMock()
    config = types.GenerateContentConfig(temperature=0.5)
    
    with patch.object(ai_client, 'client') as mock_client:
        mock_client.aio.models.generate_content = AsyncMock(return_value=mock_response)
        
        result = await ai_client.generate_content(
            model="gemini-pro",
            contents="Test prompt",
            config=config
        )
        
        assert result == mock_response
        mock_client.aio.models.generate_content.assert_called_once_with(
            model="gemini-pro",
            contents="Test prompt",
            config=config
        )
```

### 3. Tool Testing
```python
# tests/unit/test_tools/test_web_search.py
import pytest
from unittest.mock import AsyncMock, patch
import httpx

from src.tools.web_search import WebSearchTool

@pytest.fixture
def web_search_tool():
    """Create web search tool for testing."""
    return WebSearchTool(api_key="test-key")

@pytest.mark.asyncio
async def test_web_search_success(web_search_tool):
    """Test successful web search."""
    mock_response = {
        "results": [
            {"title": "Test Result", "url": "https://example.com", "snippet": "Test snippet"}
        ]
    }
    
    with patch('httpx.AsyncClient.get') as mock_get:
        mock_get.return_value.json.return_value = mock_response
        mock_get.return_value.status_code = 200
        
        result = await web_search_tool._arun("test query")
        
        assert "Test Result" in result
        assert "https://example.com" in result

@pytest.mark.asyncio
async def test_web_search_error(web_search_tool):
    """Test web search with API error."""
    with patch('httpx.AsyncClient.get') as mock_get:
        mock_get.side_effect = httpx.RequestError("Network error")
        
        result = await web_search_tool._arun("test query")
        
        assert "Error performing web search" in result

@pytest.mark.asyncio
async def test_web_search_empty_results(web_search_tool):
    """Test web search with empty results."""
    mock_response = {"results": []}
    
    with patch('httpx.AsyncClient.get') as mock_get:
        mock_get.return_value.json.return_value = mock_response
        mock_get.return_value.status_code = 200
        
        result = await web_search_tool._arun("test query")
        
        assert "No results found" in result
```

## Test Fixtures and Factories

### 1. Agent Fixtures
```python
# tests/fixtures/agent_fixtures.py
import pytest
from unittest.mock import MagicMock
from factory import Factory, Faker, SubFactory
from langchain_core.tools import BaseTool

from src.agents.base_agent import BaseAgent

class MockToolFactory(Factory):
    """Factory for creating mock tools."""
    class Meta:
        model = BaseTool
    
    name = Faker('word')
    description = Faker('sentence')

@pytest.fixture
def mock_llm():
    """Create a mock LLM for testing."""
    llm = MagicMock()
    llm.invoke.return_value = "Mock response"
    return llm

@pytest.fixture
def sample_tools():
    """Create sample tools for testing."""
    return [MockToolFactory() for _ in range(3)]

@pytest.fixture
def test_agent(mock_llm, sample_tools):
    """Create a test agent with mocked dependencies."""
    with patch('src.agents.base_agent.ChatVertexAI', return_value=mock_llm):
        return BaseAgent(
            model_name="gemini-pro",
            tools=sample_tools,
            system_prompt="Test agent",
            project_id="test-project"
        )
```

### 2. Data Fixtures
```python
# tests/fixtures/data_fixtures.py
import pytest
from factory import Factory, Faker, LazyAttribute
from datetime import datetime

class DocumentFactory(Factory):
    """Factory for creating test documents."""
    class Meta:
        model = dict
    
    content = Faker('text', max_nb_chars=1000)
    title = Faker('sentence', nb_words=4)
    url = Faker('url')
    created_at = LazyAttribute(lambda obj: datetime.utcnow().isoformat())

class ConversationFactory(Factory):
    """Factory for creating test conversations."""
    class Meta:
        model = dict
    
    user_id = Faker('uuid4')
    session_id = Faker('uuid4')
    messages = LazyAttribute(lambda obj: [
        {"role": "user", "content": "Hello"},
        {"role": "assistant", "content": "Hi there!"}
    ])

@pytest.fixture
def sample_documents():
    """Create sample documents for testing."""
    return [DocumentFactory() for _ in range(5)]

@pytest.fixture
def sample_conversation():
    """Create a sample conversation for testing."""
    return ConversationFactory()
```

## E2E Testing with Playwright

### 1. API Endpoint Testing
```python
# tests/e2e/test_api_endpoints.py
import pytest
from playwright.async_api import async_playwright
import json

@pytest.mark.asyncio
async def test_agent_chat_endpoint():
    """Test the agent chat endpoint end-to-end."""
    async with async_playwright() as p:
        # Start the API server (assuming it's running)
        browser = await p.chromium.launch()
        context = await browser.new_context()
        
        # Test API endpoint directly
        response = await context.request.post(
            "http://localhost:8000/api/v1/agents/chat",
            data=json.dumps({
                "message": "Hello, how can you help me?",
                "session_id": "test-session"
            }),
            headers={"Content-Type": "application/json"}
        )
        
        assert response.status == 200
        data = await response.json()
        assert "response" in data
        assert data["response"] is not None
        
        await browser.close()

@pytest.mark.asyncio
async def test_health_check_endpoint():
    """Test the health check endpoint."""
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        context = await browser.new_context()
        
        response = await context.request.get("http://localhost:8000/health")
        
        assert response.status == 200
        data = await response.json()
        assert data["status"] == "healthy"
        
        await browser.close()
```

## Test Configuration

### 1. conftest.py
```python
# tests/conftest.py
import pytest
import asyncio
from unittest.mock import patch
import os

# Set test environment
os.environ["ENVIRONMENT"] = "test"
os.environ["DATABASE_URL"] = "sqlite:///test.db"
os.environ["REDIS_URL"] = "redis://localhost:6379/1"

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(autouse=True)
def mock_external_apis():
    """Mock external API calls for all tests."""
    with patch('httpx.AsyncClient.get') as mock_get, \
         patch('httpx.AsyncClient.post') as mock_post:
        
        # Default mock responses
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {"status": "ok"}
        mock_post.return_value.status_code = 200
        mock_post.return_value.json.return_value = {"status": "ok"}
        
        yield

@pytest.fixture
def mock_ai_client():
    """Mock AI client for testing."""
    with patch('src.models.client.AIModelClient') as mock_client:
        mock_instance = mock_client.return_value
        mock_instance.generate_content.return_value = {
            "text": "Mock AI response",
            "usage_metadata": {
                "prompt_token_count": 10,
                "candidates_token_count": 20
            }
        }
        yield mock_instance
```

## Performance Testing

### 1. Load Testing for AI Endpoints
```python
# tests/performance/test_load.py
import pytest
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor
import httpx

@pytest.mark.asyncio
async def test_concurrent_agent_requests():
    """Test concurrent requests to agent endpoint."""
    async def make_request():
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "http://localhost:8000/api/v1/agents/chat",
                json={"message": "Test message", "session_id": "load-test"}
            )
            return response.status_code
    
    # Run 10 concurrent requests
    start_time = time.time()
    tasks = [make_request() for _ in range(10)]
    results = await asyncio.gather(*tasks)
    end_time = time.time()
    
    # Assert all requests succeeded
    assert all(status == 200 for status in results)
    
    # Assert reasonable response time
    total_time = end_time - start_time
    assert total_time < 30  # Should complete within 30 seconds
```

## Best Practices

### 1. Test Organization
- Group tests by functionality (agents, models, tools, pipelines)
- Use descriptive test names that explain the scenario
- Keep tests focused on single functionality

### 2. Mocking Strategy
- Mock external API calls (Google Cloud AI, web searches)
- Mock expensive operations (LLM calls, vector searches)
- Use dependency injection for easier testing

### 3. Test Data Management
- Use factories for creating test data
- Keep test data minimal and focused
- Clean up test data after each test

### 4. Coverage Requirements
- Maintain 80% code coverage minimum
- Focus on critical business logic
- Test error handling and edge cases

### 5. Performance Considerations
- Mock LLM calls to avoid API costs and latency
- Use async tests for async code
- Test concurrent scenarios for production readiness
