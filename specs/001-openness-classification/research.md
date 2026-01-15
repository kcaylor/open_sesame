# Technology Research: Openness Classification Model Implementation

## 1. nbdev Framework

### Decision
Use **nbdev 2.x** (specifically nbdev 2.3.26 or later) as the primary development framework for building the openness classification scientific Python library.

### Rationale

nbdev provides a notebook-driven development approach that is particularly well-suited for scientific Python libraries:

1. **Unified Development Environment**: Write code, tests, and documentation all within Jupyter notebooks, eliminating context-switching and keeping related elements together.

2. **Automatic Best Practices**: Python best practices are automatically enforced, including proper `__all__` exports, module organization, and package structure.

3. **Built-in CI/CD**: Continuous integration with GitHub Actions is provided out-of-the-box, automatically running tests (via `nbdev_test`) and rebuilding documentation on every push.

4. **High-Quality Documentation**: Documentation is automatically generated using Quarto and can be hosted on GitHub Pages, with support for LaTeX, searchable content, and automatic hyperlinking between components.

5. **Git-Friendly**: Jupyter/Git hooks clean unwanted metadata and render merge conflicts in a human-readable format, addressing one of the major pain points of notebook-based development.

6. **Two-Way Sync**: Allows syncing between notebooks and plaintext Python modules, enabling IDE usage for code navigation and quick edits when needed.

7. **Proven in Production**: fastai, a leading deep learning library built on PyTorch, is developed entirely with nbdev, demonstrating its viability for complex scientific libraries.

### Project Structure Best Practices

1. **Notebook Organization**:
   - Use `#default_exp <module_name>` at the start of each notebook to specify the target Python module
   - Organize notebooks by logical components (e.g., `00_core.ipynb`, `01_providers.ipynb`, `02_classification.ipynb`)
   - Keep related functionality together in the same notebook for better narrative flow

2. **Testing Strategy**:
   - Write tests as ordinary notebook cells using nbdev's testing utilities (e.g., `test_eq`, `test_close`)
   - Tests run in parallel with `nbdev_test` command
   - CI/CD automatically runs tests on every commit via GitHub Actions

3. **Documentation Generation**:
   - Use markdown cells for narrative documentation
   - Code cells automatically generate API documentation
   - Use `#| export` directive to mark cells for export to Python modules
   - Use `#| hide` to exclude cells from documentation

4. **Initialization**:
   - Run `nbdev_new` to create project structure
   - Configure `settings.ini` with project metadata
   - Run `nbdev_install_hooks` to set up Git hooks

### Alternatives Considered

1. **Traditional Python Package Structure**:
   - More mature tooling ecosystem (setuptools, poetry, etc.)
   - Better IDE support
   - **Rejected because**: Separates code, tests, and documentation, making it harder to maintain scientific libraries where narrative explanation is crucial

2. **Jupyter Book + Sphinx**:
   - Flexible documentation system
   - Wide adoption in scientific community
   - **Rejected because**: Doesn't provide the same level of integration between notebooks and Python package development; requires manual synchronization

3. **Cookiecutter Data Science**:
   - Well-established project template
   - Good for data science workflows
   - **Rejected because**: Focuses on analysis workflows rather than library development; lacks nbdev's automatic documentation and testing capabilities

### References

- [nbdev Official Documentation](https://nbdev.fast.ai/)
- [How nbdev helps us structure our data science workflow in Jupyter Notebooks](https://www.overstory.com/blog/how-nbdev-helps-us-structure-our-data-science-workflow-in-jupyter-notebooks)
- [nbdev GitHub Repository](https://github.com/AnswerDotAI/nbdev)
- [Machine Learning Lifecycle with MLOps: Github Actions, Label Studio, Iterative.ai and NBDEV](https://towardsdatascience.com/machine-learning-lifecycle-with-mlops-github-actions-label-studio-iterative-ai-and-nbdev-30515f444a3e/)
- [nbdev v2 review: Git-friendly Jupyter Notebooks](https://www.infoworld.com/article/2337892/nbdev-v2-review-git-friendly-jupyter-notebooks.html)
- [fastai Library (built with nbdev)](https://docs.fast.ai/)
- [Fastai: A Layered API for Deep Learning](https://www.mdpi.com/2078-2489/11/2/108)

---

## 2. LLM Provider Integration

### Decision
Implement a **unified abstraction layer** using the **Adapter pattern** combined with **LiteLLM** as the underlying provider interface for integrating Claude API, OpenAI API, and Ollama.

### Rationale

1. **LiteLLM as Foundation**:
   - Provides out-of-the-box support for 100+ LLM providers including Claude (Anthropic), OpenAI, and Ollama
   - Offers a unified OpenAI-compatible interface, reducing implementation complexity
   - Includes built-in retry logic, fallback support, and error handling
   - Active maintenance and production-ready reliability features

2. **Adapter Pattern Overlay**:
   - Provides an additional abstraction layer specific to our use case
   - Allows customization of provider-specific behaviors without modifying LiteLLM
   - Enables easy testing and mocking of LLM providers
   - Makes it simple to add custom providers or switch away from LiteLLM if needed

3. **Configuration Management**:
   - Store API keys and endpoints in environment variables or configuration files
   - Use a centralized configuration class to manage provider settings
   - Support for multiple configurations (development, testing, production)
   - Example structure:
     ```python
     OPENNESS_CLAUDE_API_KEY=sk-ant-...
     OPENNESS_OPENAI_API_KEY=sk-...
     OPENNESS_OLLAMA_ENDPOINT=http://localhost:11434
     ```

4. **Error Handling & Retry Logic**:
   - Leverage LiteLLM's built-in retry policies:
     - `AuthenticationErrorRetries`: API key issues
     - `TimeoutErrorRetries`: Request timeouts
     - `RateLimitErrorRetries`: Rate limit exceeded
     - `InternalServerErrorRetries`: Server-side errors
   - Implement custom retry logic for classification-specific failures
   - Use exponential backoff for transient errors
   - Provide fallback providers when primary provider fails

5. **Cost Tracking & Rate Limiting**:
   - Use LiteLLM's virtual keys for budget limits and rate limiting
   - Track token usage per classification request
   - Implement configurable rate limits (TPM - tokens per minute, RPM - requests per minute)
   - Log costs for analysis and optimization

### Implementation Pattern

```python
from abc import ABC, abstractmethod
from typing import Dict, List, Optional
import litellm

class LLMProvider(ABC):
    """Abstract base class for LLM providers."""

    @abstractmethod
    def complete(self, prompt: str, **kwargs) -> str:
        """Generate a completion for the given prompt."""
        pass

    @abstractmethod
    def get_provider_name(self) -> str:
        """Return the name of the provider."""
        pass

class LiteLLMAdapter(LLMProvider):
    """Adapter for LiteLLM-supported providers."""

    def __init__(self, model: str, **config):
        self.model = model
        self.config = config

    def complete(self, prompt: str, **kwargs) -> str:
        response = litellm.completion(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            num_retries=self.config.get("num_retries", 3),
            timeout=self.config.get("timeout", 30),
            **kwargs
        )
        return response.choices[0].message.content

    def get_provider_name(self) -> str:
        return self.model.split("/")[0] if "/" in self.model else self.model

class ClassificationModel:
    """Main classification model using any LLM provider."""

    def __init__(self, provider: LLMProvider):
        self.provider = provider

    def classify(self, text: str, categories: List[str]) -> Dict:
        prompt = self._build_classification_prompt(text, categories)
        response = self.provider.complete(prompt)
        return self._parse_response(response)
```

### Alternatives Considered

1. **Direct API Integration**:
   - Write custom clients for each provider
   - **Rejected because**: Requires significant maintenance effort; duplicates error handling, retry logic, and other infrastructure code

2. **AbstractCore**:
   - Unified LLM provider interface with centralized configuration
   - Production-ready infrastructure
   - **Rejected because**: Less mature than LiteLLM; smaller community and fewer examples

3. **LangChain**:
   - Comprehensive LLM application framework
   - Rich ecosystem of tools and integrations
   - **Rejected because**: Too heavyweight for our focused use case; adds unnecessary complexity and dependencies

4. **just-prompt (MCP Server)**:
   - Model Control Protocol implementation
   - Unified interface for multiple providers
   - **Rejected because**: Newer and less battle-tested than LiteLLM; additional server layer adds complexity

### References

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [LiteLLM: An open-source gateway for unified LLM access](https://www.infoworld.com/article/3975290/litellm-an-open-source-gateway-for-unified-llm-access.html)
- [Multi-Provider Chat App with LiteLLM](https://medium.com/@richardhightower/multi-provider-chat-app-litellm-streamlit-ollama-gemini-claude-perplexity-and-modern-llm-afd5218c7eab)
- [LiteLLM API Key Management](https://deepwiki.com/BerriAI/litellm/3.5.1-api-key-management)
- [LiteLLM Reliability Features](https://docs.litellm.ai/docs/proxy/reliability)
- [LiteLLM Configuration Settings](https://docs.litellm.ai/docs/proxy/config_settings)
- [Adapter Pattern in Python](https://refactoring.guru/design-patterns/adapter/python/example)
- [Level Up Your Python with 3 Essential Design Patterns for AI and LLM Projects](https://medium.com/@ethanbrooks42/level-up-your-python-with-3-essential-design-patterns-for-ai-and-llm-projects-525597fad295)
- [Design Patterns in Python for AI and LLM Engineers](https://www.unite.ai/design-patterns-in-python-for-ai-and-llm-engineers-a-practical-guide/)
- [llm-adapter GitHub Repository](https://github.com/bigsk1/llm-adapter)
- [AbstractCore - Unified LLM Provider Interface](https://www.abstractcore.ai/)

---

## 3. Few-Shot Learning Implementation

### Decision
Implement a **semantic similarity-based few-shot learning approach** using:
- **kNN (k-Nearest Neighbors) example selection** with sentence embeddings
- **Chain-of-Thought (CoT) reasoning** for classification explanations
- **Optimized temperature and sampling parameters** based on classification requirements

### Rationale

1. **kNN-Based Example Selection**:
   - **Superior Performance**: KATE (kNN Approach for Task-specific Examples) substantially improves GPT-3's results over random sampling on natural language understanding and generation tasks
   - **Semantic Relevance**: Selects examples that are semantically similar to the input text using pre-trained sentence encoders (BERT, RoBERTa, or sentence-transformers)
   - **Dynamic Selection**: Adapts to each input by finding the most relevant examples from the training set
   - **Label Distribution**: Can be configured to balance example selection across categories

2. **Chain-of-Thought Reasoning**:
   - **Improved Classification**: CoT prompting significantly improves the ability of LLMs to perform complex reasoning by generating intermediate reasoning steps
   - **Transparency**: Provides explanations for classification decisions, enhancing interpretability
   - **Error Analysis**: CoT explanations help identify why certain classifications were made, facilitating model improvement
   - **Implementation**: Use "think step-by-step" instructions or provide CoT exemplars in the few-shot examples

3. **Temperature Optimization**:
   - **Low Temperature (0.0-0.3)**: For classification tasks requiring deterministic, fact-based outputs
     - More consistent predictions
     - Always picks the highest probability token
     - Recommended for production classification
   - **Medium Temperature (0.4-0.7)**: For exploratory analysis or when some creativity is beneficial
   - **High Temperature (0.8-1.0)**: Generally not recommended for classification tasks
   - **Recommendation**: Start with temperature=0.1 for openness classification to ensure consistency

4. **Additional Sampling Parameters**:
   - **top_p (nucleus sampling)**: Set to 0.9-0.95 to balance diversity and quality
   - **max_tokens**: Set based on expected classification response length (typically 100-200 for classification with brief explanation)
   - **presence_penalty & frequency_penalty**: Keep at 0 for classification tasks to avoid biasing against repeated category names

### Implementation Strategy

```python
from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List, Dict, Tuple

class FewShotClassifier:
    """Few-shot classifier with kNN example selection and CoT reasoning."""

    def __init__(self, provider: LLMProvider, encoder_model: str = "all-MiniLM-L6-v2"):
        self.provider = provider
        self.encoder = SentenceTransformer(encoder_model)
        self.examples: List[Dict] = []
        self.example_embeddings = None

    def add_examples(self, examples: List[Dict]):
        """Add training examples and compute embeddings."""
        self.examples = examples
        texts = [ex["text"] for ex in examples]
        self.example_embeddings = self.encoder.encode(texts)

    def select_examples(self, text: str, k: int = 5) -> List[Dict]:
        """Select k most similar examples using kNN."""
        text_embedding = self.encoder.encode([text])[0]

        # Compute cosine similarity
        similarities = np.dot(self.example_embeddings, text_embedding) / (
            np.linalg.norm(self.example_embeddings, axis=1) * np.linalg.norm(text_embedding)
        )

        # Get indices of top k similar examples
        top_k_indices = np.argsort(similarities)[-k:][::-1]

        return [self.examples[i] for i in top_k_indices]

    def build_few_shot_prompt(self, text: str, categories: List[str], k: int = 5) -> str:
        """Build few-shot prompt with CoT reasoning."""
        selected_examples = self.select_examples(text, k)

        prompt = f"""You are classifying research articles based on their openness level.

Categories: {', '.join(categories)}

Here are some examples with step-by-step reasoning:

"""

        for i, example in enumerate(selected_examples, 1):
            prompt += f"""Example {i}:
Text: {example['text']}
Reasoning: {example['reasoning']}
Classification: {example['category']}

"""

        prompt += f"""Now classify the following text. Think step-by-step:

Text: {text}
Reasoning: """

        return prompt

    def classify(self, text: str, categories: List[str], k: int = 5) -> Dict:
        """Classify text using few-shot learning with CoT."""
        prompt = self.build_few_shot_prompt(text, categories, k)

        response = self.provider.complete(
            prompt,
            temperature=0.1,  # Low temperature for consistency
            top_p=0.95,
            max_tokens=200
        )

        return self._parse_cot_response(response, categories)
```

### Few-Shot Prompt Structure

Each few-shot example should include:

1. **Input Text**: The article excerpt or description
2. **Reasoning (CoT)**: Step-by-step explanation of classification
3. **Output Category**: Final classification label

Example:
```
Text: "All data and code are available in our GitHub repository under MIT license."
Reasoning: The article explicitly states that both data and code are available with an open source license (MIT). This indicates full openness with no restrictions.
Classification: Fully Open
```

### Example Selection Best Practices

1. **Diversity**: Ensure examples cover all categories
2. **Quality**: Use high-quality, unambiguous examples
3. **Relevance**: Select examples semantically similar to the input
4. **Balance**: Maintain proportional representation of categories (or use stratified sampling)
5. **Size**: Start with k=3-5 examples; increase if performance is insufficient

### Alternatives Considered

1. **Random Example Selection**:
   - Simpler implementation
   - No need for embedding models
   - **Rejected because**: Significantly lower performance than semantic similarity-based selection

2. **Zero-Shot Classification**:
   - No need for training examples
   - Simpler prompt engineering
   - **Rejected because**: Lower accuracy for domain-specific classification tasks; lacks the benefit of demonstrating expected reasoning patterns

3. **Fine-Tuning**:
   - Potentially highest accuracy
   - Model specialized to the task
   - **Rejected because**: Requires large labeled datasets; more expensive; less flexible; harder to update when categories change

4. **Complexity-Based Example Selection**:
   - Aligns syntactico-semantic complexity of test and training examples
   - **Rejected because**: More complex to implement; marginal gains over semantic similarity for most classification tasks

5. **TransPrompt Framework**:
   - Captures cross-task knowledge
   - Transferable prompting
   - **Rejected because**: More complex than needed for single classification task; benefits primarily when working across multiple related tasks

### References

- [Chain-of-Thought Prompting Elicits Reasoning in Large Language Models](https://arxiv.org/abs/2201.11903)
- [Chain-of-Thought Prompting Guide](https://www.promptingguide.ai/techniques/cot)
- [K-Nearest Neighbor (KNN) Prompting](https://learnprompting.org/docs/advanced/few_shot/k_nearest_neighbor_knn)
- [Few-Shot Text Classification](https://few-shot-text-classification.fastforwardlabs.com/)
- [True Few-Shot Learning with Prompts—A Real-World Perspective](https://direct.mit.edu/tacl/article/doi/10.1162/tacl_a_00485/111728/True-Few-Shot-Learning-with-Prompts-A-Real-World)
- [Designing Informative Metrics for Few-Shot Example Selection](https://arxiv.org/html/2403.03861v3)
- [The Effect of Sampling Temperature on Problem Solving in Large Language Models](https://arxiv.org/html/2402.05201v1)
- [LLM Settings - Prompt Engineering Guide](https://www.promptingguide.ai/introduction/settings)
- [T2 of Thoughts: Temperature Tree Elicits Reasoning in Large Language Models](https://arxiv.org/html/2405.14075v2)
- [Tracing Thought: Using Chain-of-Thought Reasoning to Identify the LLM Behind AI-Generated Text](https://arxiv.org/abs/2504.16913)
- [A Guide to Controlling LLM Model Output](https://ivibudh.medium.com/a-guide-to-controlling-llm-model-output-exploring-top-k-top-p-and-temperature-parameters-ed6a31313910)
- [Few-Shot Prompting Guide](https://www.promptingguide.ai/techniques/fewshot)
- [What Makes Good In-Context Examples for GPT-3?](https://www.researchgate.net/publication/361069031_What_Makes_Good_In-Context_Examples_for_GPT-3)
- [A comprehensive taxonomy of prompt engineering techniques](https://jamesthez.github.io/files/liu-fcs26.pdf)

---

## Summary of Technology Stack

### Core Framework
- **nbdev 2.x**: Notebook-driven development with automatic documentation, testing, and CI/CD

### LLM Integration
- **LiteLLM**: Unified provider interface for Claude, OpenAI, and Ollama
- **Adapter Pattern**: Custom abstraction layer for flexibility and testability

### Classification Approach
- **kNN Example Selection**: Semantic similarity-based few-shot learning
- **Chain-of-Thought**: Reasoning-enhanced classification with explanations
- **Sentence Transformers**: Embedding models for semantic similarity (e.g., all-MiniLM-L6-v2)
- **Optimized Parameters**: Low temperature (0.1), nucleus sampling (top_p=0.95)

### Supporting Libraries
- `sentence-transformers`: For generating text embeddings
- `numpy`: For similarity computations
- `litellm`: For LLM provider abstraction
- `python-dotenv`: For configuration management
- `pydantic`: For configuration validation

This technology stack provides a robust, maintainable, and scientifically sound foundation for implementing the openness classification model with production-ready reliability and academic rigor.
