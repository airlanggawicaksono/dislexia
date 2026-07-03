from enum import Enum


class PostProcessStatus(str, Enum):
    """Lifecycle status of ARHQ post-processing for a screening session.

    Derived from `feature_history.metadata` on read — never stored on its own,
    so it can't drift from the actual result.
    """

    NOT_STARTED = "not_started"  # no metadata, or metadata lacks ahrq_status
    SUCCESS = "success"          # metadata.ahrq_status == "success"
    FAILED = "failed"            # metadata.ahrq_status == "failed"
