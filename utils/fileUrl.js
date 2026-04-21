const buildFileUrl = (req, filePath) => {
  if (!filePath) return null;

  const normalizedPath = filePath.replace(/\\/g, '/');
  const cleanPath = normalizedPath.startsWith('/')
    ? normalizedPath.slice(1)
    : normalizedPath;

  return `${req.protocol}://${req.get('host')}/${cleanPath}`;
};

module.exports = {
  buildFileUrl,
};