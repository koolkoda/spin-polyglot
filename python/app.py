import json

from spin_sdk.http import Handler, Request, Response


class HttpHandler(Handler):
    async def handle_request(self, request: Request) -> Response:
        path = request.headers.get("spin-path-info", "/")
        body = json.dumps(
            {
                "component": "python",
                "message": "Hello from Spin",
                "path": path,
            },
            separators=(",", ":"),
        )
        return Response(
            200,
            {"content-type": "application/json"},
            body.encode("utf-8"),
        )
