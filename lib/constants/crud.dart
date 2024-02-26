// ignore_for_file: inference_failure_on_collection_literal

const Map<String, dynamic> kCrudEmpty = {
  'categories': {
    'operations': {
      'create': [],
      'update': [],
      'delete': [],
    },
  },
  'tasks': {
    'operations': {
      'create': [],
      'update': [],
      'delete': [],
    },
  },
};

const Map<String, dynamic> kCrudExample = {
  'categories': {
    'operations': {
      'create': [
        {
          'title': 'Неделя 1: Сортировка',
          'shortTitle': 'Сортировка',
          'description': 'example description',
          'sortingNumber': 1,
        }
      ],
      'update': [
        {
          'id': 0,
          'title': 'example title',
          'shortTitle': 'example shortTitle',
          'description': 'example description',
          'sortingNumber': 1,
        }
      ],
      'delete': [
        {
          'id': 0,
        }
      ],
    },
  },
  'tasks': {
    'operations': {
      'create': [
        {
          'slug': 'decode-ways',
          'category': 0,
          'title': '91. Decode Ways',
          'link': 'https://leetcode.com/problems/decode-ways/description/',
          'complexity': 'easy|medium|hard',
        }
      ],
      'update': [
        {
          'slug': 'decode-ways',
          'category': 0,
          'title': '91. Decode Ways',
          'link': 'https://leetcode.com/problems/decode-ways/description/',
          'complexity': 'hard',
        }
      ],
      'delete': [
        {
          'slug': 'decode-ways',
        }
      ],
    },
  },
};
