declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export async function fetchNui<T = any>(eventName: string, data?: any): Promise<T> {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  };

  const resourceName = (window.GetParentResourceName ? window.GetParentResourceName() : 'nui-frame-app');

  const resp = await fetch(`https://${resourceName}/${eventName}`, options);

  const respFormatted = await resp.json();

  return respFormatted;
}
