from setuptools import setup, find_packages

setup(
    name="ultsql",
    version="1.0.18",
    description="Universal Python client for the UltSQL 100% Pure-Dart multimodal database engine.",
    long_description=open("README.md", encoding="utf-8").read(),
    long_description_content_type="text/markdown",
    author="Om Patel",
    url="https://github.com/ompatel3158/ULTSQL",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.7",
)
