import { AutoRouter } from 'itty-router';

const router = AutoRouter();

router.all('*', (request: Request) => {
  const path = request.headers.get('spin-path-info') ?? new URL(request.url).pathname;

  return Response.json({
    component: 'typescript',
    message: 'Hello from Spin',
    path,
  });
});

//@ts-ignore
addEventListener('fetch', (event: FetchEvent) => {
  event.respondWith(router.fetch(event.request));
});
