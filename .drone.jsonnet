local IMAGE_NAME = 'rspamd/rbldnsd';
local DEBIAN_VERSION = 'bookworm';

local docker_defaults = {
  username: {
    from_secret: 'docker_username',
  },
  password: {
    from_secret: 'docker_password',
  },
};

local pipeline_defaults = {
  kind: 'pipeline',
  type: 'docker',
};

local trigger_on_tag = {
  trigger: {
    branch: {
      include: [
        'main',
      ],
    },
    event: {
      include: [
        'tag',
      ],
    },
  },
};

local platform(arch) = {
  platform: {
    os: 'linux',
    arch: arch,
  },
};

local make_prod_image(arch) = {
  name: 'prod_image_' + arch,
  steps: [
    {
      name: 'prod_image',
      image: 'rspamd/drone-docker-plugin',
      privileged: true,
      settings: {
        dockerfile: 'Dockerfile',
        label_schema: [
          'docker.dockerfile=Dockerfile',
        ],
        build_args: [
          'DEBIAN_VERSION=' + DEBIAN_VERSION,
          'RBLDNSD_VERSION=${DRONE_SEMVER_SHORT}',
        ],
        repo: IMAGE_NAME,
        tags: [
          'latest-' + arch,
        ],
      } + docker_defaults,
    },
  ],
} + platform(arch) + trigger_on_tag + pipeline_defaults;

local signature_placeholder = {
  kind: 'signature',
  hmac: '0000000000000000000000000000000000000000000000000000000000000000',
};

local make_multiarch_prod_image = {
  local image_tag = 'latest',
  name: 'multiarch_prod_image',
  depends_on: [
    'prod_image_amd64',
    'prod_image_arm64',
  ],
  steps: [
    {
      name: 'multiarch_image',
      image: 'plugins/manifest',
      settings: {
        target: std.format('%s:%s', [IMAGE_NAME, image_tag]),
        template: std.format('%s:%s-ARCH', [IMAGE_NAME, image_tag]),
        platforms: [
          'linux/amd64',
          'linux/arm64',
        ],
        tags: [
          '${DRONE_SEMVER_SHORT}',
          '${DRONE_SEMVER_SHORT}-${DRONE_SEMVER_BUILD}',
        ],
      } + docker_defaults,
    },
  ],
} + trigger_on_tag + pipeline_defaults;

[
  make_prod_image('amd64'),
  make_prod_image('arm64'),
  make_multiarch_prod_image,
  signature_placeholder,
]
