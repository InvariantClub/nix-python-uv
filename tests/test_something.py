import pytest
import time


@pytest.mark.pure
def test_something():
  # Note: The `sleep` here shows that, if nothing has changed in the source
  # tree, and the test is successful, the test is not re-evaluated.
  time.sleep(3)
  assert True


@pytest.mark.pure
def test_something_else():
  assert True
