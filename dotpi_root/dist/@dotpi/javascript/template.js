import fs from 'node:fs/promises';
import compile from 'template-literal';

export async function renderFile(templateFile, data = {}) {
  try {
  const template = await fs.readFile(templateFile, 'utf8');
  const render = compile(template);
  return render(data);
  } catch (error) {
    throw error;
  }
}

