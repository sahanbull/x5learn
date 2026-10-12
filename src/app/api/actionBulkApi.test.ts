import { postActionsBulk } from './api';

it('posts the supplied bulk payload to action/bulk/ with session credentials', async () => {
  const originalFetch = global.fetch;
  const fetch = jest.fn().mockResolvedValue({
    ok: true,
    json: async () => ({ result: 'Actions logged' }),
  });
  global.fetch = fetch;
  try {
    const payload = {
      action_type_ids: [1, 2],
      params_list: ['{"oer_id":42}', '{}'],
    };
    await postActionsBulk(payload);
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/action/bulk/'),
      expect.objectContaining({
        method: 'POST',
        credentials: 'include',
        body: JSON.stringify(payload),
      }),
    );
    expect(fetch.mock.calls[0][1].headers.get('Content-Type')).toBe(
      'application/json',
    );
  } finally {
    global.fetch = originalFetch;
  }
});
