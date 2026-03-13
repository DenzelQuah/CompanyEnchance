from app.financial_service import FinancialService
from app.models import DailyFinancialLog, DailyFinancialLogListResponse, FinancialTargetResponse


def _service() -> FinancialService:
    return FinancialService()


def test_normalize_month_and_date_validation() -> None:
    service = _service()
    assert service._normalize_month("2026-03") == "2026-03"
    assert service._normalize_date("2026-03-07") == "2026-03-07"

    try:
        service._normalize_month("03-2026")
        assert False, "Expected ValueError for invalid month format."
    except ValueError:
        pass

    try:
        service._normalize_date("2026/03/07")
        assert False, "Expected ValueError for invalid date format."
    except ValueError:
        pass


def test_growth_graph_projection_and_actual_series() -> None:
    service = _service()
    service.get_target = lambda user_id, month: FinancialTargetResponse(
        user_id=user_id,
        month=month,
        monthly_budget_rm=3100,
        target_growth_pct=15,
    )
    service.get_daily_logs = lambda user_id, month: DailyFinancialLogListResponse(
        items=[
            DailyFinancialLog(
                id="a",
                user_id=user_id,
                log_date=f"{month}-01",
                revenue_rm=120,
                expense_rm=30,
                note=None,
            ),
            DailyFinancialLog(
                id="b",
                user_id=user_id,
                log_date=f"{month}-02",
                revenue_rm=130,
                expense_rm=40,
                note=None,
            ),
        ]
    )

    graph = service.get_growth_graph(user_id="u1", month="2026-03")
    assert graph.month == "2026-03"
    assert len(graph.dates) >= 28
    assert graph.projection_growth_pct[0] > 0
    assert graph.projection_growth_pct[-1] == 15
    assert graph.actual_growth_pct[1] != graph.actual_growth_pct[0]


def test_growth_graph_handles_zero_budget() -> None:
    service = _service()
    service.get_target = lambda user_id, month: FinancialTargetResponse(
        user_id=user_id,
        month=month,
        monthly_budget_rm=0,
        target_growth_pct=10,
    )
    service.get_daily_logs = lambda user_id, month: DailyFinancialLogListResponse(items=[])
    graph = service.get_growth_graph(user_id="u1", month="2026-03")
    assert all(v == 0 for v in graph.actual_growth_pct)
