import os
import sys
from setuptools import setup, find_packages

# Determine bdist_wheel platform behavior
try:
    from wheel.bdist_wheel import bdist_wheel as _bdist_wheel

    class bdist_wheel(_bdist_wheel):
        def finalize_options(self):
            super().finalize_options()
            # Mark wheel as not pure if building with platform-specific binaries
            if getattr(self, "plat_name", None) and self.plat_name != "any":
                self.root_is_pure = False

        def get_tag(self):
            python, abi, plat = super().get_tag()
            # If a custom platform is specified, keep python="py3", abi="none"
            if self.plat_name and self.plat_name != "any":
                return "py3", "none", self.plat_name
            return python, abi, plat

    cmdclass = {"bdist_wheel": bdist_wheel}
except ImportError:
    cmdclass = {}

readme_path = os.path.join(os.path.dirname(__file__), "README.md")
long_description = ""
if os.path.exists(readme_path):
    with open(readme_path, encoding="utf-8") as f:
        long_description = f.read()

setup(
    name="ultsql",
    version="1.0.29",
    description="Universal Python client and embedded engine for UltSQL multimodal database.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Om Patel",
    author_email="om.business3158@gmail.com",
    license="FSL-1.1-MIT",
    url="https://github.com/ompatel3158/ULTSQL",
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    package_data={
        "ultsql": [
            "bin/*",
            "bin/ultsql*",
            "py.typed",
        ]
    },
    include_package_data=True,
    cmdclass=cmdclass,
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Programming Language :: Python :: 3.14",
        "Topic :: Database",
        "Topic :: Database :: Database Engines/Servers",
    ],
    python_requires=">=3.7",
)
