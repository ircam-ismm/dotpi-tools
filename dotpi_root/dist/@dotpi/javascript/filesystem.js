import fs from 'node:fs/promises';

// like node:fs.symlink but replace destination
export async function symlink(source, destination) {

  try {
    const destinationTmp = `${destination}_dotpi_tmp_${process.pid}`;
    await fs.symlink(source, destinationTmp);
    // atomic in POSIX. Replace file or symlink (not directory)
    await fs.rename(destinationTmp, destination)
      .catch(async (error) => {
        if (error.code === 'EISDIR') {
          // remove existing directory and try again
          await fs.rm(destination, { recursive: true });
          return await fs.rename(destinationTmp, destination);
        }

        // give up for other errors
        throw error;
      });
  } catch (error) {
    throw error;
  }

}
